import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/model/login_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart' as hive;

import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/services/access_control_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final String username;
  final LoginData currentUser;
  late final hive.Box<LogModel> _myBox;

  String get _storageKey => '${username}_user_logs_data';

  get _boxName => 'offline_logs_${currentUser.teamId}';

  Future<void> init() async {
      // 1. Cek apakah box sudah terbuka untuk mencegah error
      if (!Hive.isBoxOpen(_boxName)) {
        await LogHelper.writeLog("Membuka Hive Box: $_boxName", level: 2);
        await Hive.openBox<LogModel>(_boxName);
      }

      _myBox = Hive.box<LogModel>(_boxName);

      await loadFromDisk();
  }

  LogController({required this.username, required this.currentUser}) {
    loadFromDisk();
  }

  void refreshUI(List<LogModel> logs) {
    logsNotifier.value = List.from(logs);
    filteredLogs.value = List.from(logs);
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
    LogCategory category,
  ) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      category: category,
      date: DateTime.now(),
      authorId: authorId,
      teamId: teamId,
      synced: false,
    );

    await _myBox.put(newLog.id, newLog);
    refreshUI([...logsNotifier.value, newLog]);

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      newLog.markAsSync();
      await _myBox.put(newLog.id, newLog);
      refreshUI(logsNotifier.value);
      await LogHelper.writeLog(
        "SUCCESS: Data tersinkron ke Cloud",
        source: "log_controller.dart",
      );
      await _myBox.put(newLog.id, newLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online",
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    int index,
    String title,
    String desc,

    String authorId,
    String teamId,
    LogCategory category,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama agar MongoDB mengenali dokumen ini
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category,
      authorId: authorId,
      teamId: teamId,
      synced: false,
    );

    await _myBox.put(oldLog.id, updatedLog);
    currentLogs[index] = updatedLog;
    refreshUI(currentLogs);

    try {
      // 1. Jalankan update di MongoService (Tunggu konfirmasi Cloud)
      await MongoService().updateLog(updatedLog);
      updatedLog.markAsSync();
      currentLogs[index] = updatedLog;
      refreshUI(currentLogs);

      // 2. Jika sukses, baru perbarui db lokal
      await _myBox.put(updatedLog.id, updatedLog);

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Data di UI tidak berubah jika proses di Cloud gagal
    }
  }

  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    if (!AccessControlService.canPerform(
      currentUser.role,
      AccessControlService.actionDelete,
      isOwner: targetLog.authorId == currentUser.id,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );
      return; // Hentikan proses jika tidak punya izin
    }

    targetLog.markAsPendingDelete();
    await _myBox.put(targetLog.id, targetLog);

    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;

    try {
      // 1. Hapus data di MongoDB Atlas (Tunggu konfirmasi Cloud)
      await MongoService().deleteLog(targetLog.objId!);
      await _myBox.delete(targetLog.id);

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> syncData() async {
    final localData = _myBox.values.toList();
    var cloudData = [];
    try {
      cloudData = await MongoService().getLogs(currentUser.teamId);
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Tidak bisa syncing, ${e.toString()}",
        level: 2,
      );
      return;
    }

    final localMap = {for (var log in localData) log.id: log};
    final cloudMap = {for (var log in cloudData) log.id: log};

    for (var localLog in localData) {
      if (localLog.id == null) continue;
      final cloudLog = cloudMap[localLog.id];

      // JIKA INI ADALAH TOMBSTONE (Pending Delete)
      if (localLog.pendingDelete) {
        if (cloudLog != null) {
          // LWW: Apakah cloud lebih baru dari waktu kita menghapus?
          if (localLog.date.isAfter(cloudLog.date)) {
            await MongoService().deleteLog(localLog.objId!);
            await _myBox.delete(localLog.id); // Selesai, hapus dari lokal
          } else {
            // Cloud menang, batal hapus
            await _myBox.put(localLog.id, cloudLog);
          }
        } else {
          // Sudah tidak ada di cloud, bersihkan lokal
          await _myBox.delete(localLog.id);
          await LogHelper.writeLog(
            "Deleted pending delete log ${localLog.id} from disk",
            level: 2,
            source: "log_controller.dart - loadFromDisk",
          );
        }
        continue; // Lanjut ke log berikutnya
      }

      // INSERT ATAU UPDATE NORMAL (LWW)
      if (cloudLog == null) {
        // Hanya ada di lokal -> Insert
        await MongoService().insertLog(localLog);
        localLog.markAsSync();
        await _myBox.put(localLog.id, localLog);
      } else {
        // Ada di dua-duanya -> Adu Date (LWW)
        if (localLog.date.isAfter(cloudLog.date)) {
          await MongoService().updateLog(localLog);
          localLog.markAsSync();
          await _myBox.put(localLog.id, localLog);
        } else if (cloudLog.date.isAfter(localLog.date)) {
          await _myBox.put(localLog.id, cloudLog);
        }
      }
    }

    // Tarik data baru dari cloud
    for (var cloudLog in cloudData) {
      if (cloudLog.id == null) continue;
      if (!localMap.containsKey(cloudLog.id)) {
        await _myBox.put(cloudLog.id, cloudLog);
      }
    }

    // Pastikan UI HANYA menampilkan log yang tidak di-delete
    final finalData = _myBox.values.where((log) => !log.pendingDelete).toList();
    logsNotifier.value = finalData;
    filteredLogs.value = finalData;
  }

  Future<void> loadFromDisk() async {
    final allData = _myBox.values.toList();
    await LogHelper.writeLog(
      "Loaded ${allData.length} logs from disk, Pending delete: ${allData.where((log) => log.pendingDelete).length}",
      level: 2,
      source: "log_controller.dart - loadFromDisk",
    );
    logsNotifier.value = _myBox.values
        .where((log) => !log.pendingDelete)
        .toList();

    filteredLogs.value = logsNotifier.value;
    await LogHelper.writeLog(
      "Loaded ${logsNotifier.value.length} logs from disk",
      level: 2,
      source: "log_controller.dart - loadFromDisk",
    );
    await syncData();
  }
}
