import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';

import 'package:logbook_app_001/helpers/log_helper.dart';
part 'log_model.g.dart';

@HiveType(typeId: 1)
enum LogCategory {
  @HiveField(0)
  pekerjaan("Pekerjaan"),

  @HiveField(1)
  pribadi("Pribadi"),

  @HiveField(2)
  urgent("Urgent");

  final String label;

  factory LogCategory.fromString(String value) {
    return LogCategory.values.firstWhere(
      (element) => element.name == value,
      orElse: () => LogCategory.pekerjaan,
    );
  }

  const LogCategory(this.label);
}

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final LogCategory category;

  @HiveField(5)
  final String authorId; // BARU

  @HiveField(6)
  final String teamId; // BARU

  @HiveField(7, defaultValue: false) // Tambahkan defaultValue
  bool synced;

  @HiveField(8, defaultValue: false) // Tambahkan defaultValue
  bool pendingDelete;

  ObjectId? get objId {
    if (!ObjectId.isValidHexId(id ?? "")) {
      return null;
    }
    return ObjectId.fromHexString(id!);
  }

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
    required this.authorId,
    required this.teamId,
    required this.synced,
    this.pendingDelete = false,
  });

  void markAsSync() {
    synced = true;
  }

  void markAsNotSync() {
    synced = false;
  }

  void markAsPendingDelete() {
    pendingDelete = true;
    date = DateTime.now();
  }

  void markAsNotPendingDelete() {
    pendingDelete = false;
  }

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    LogCategory category = LogCategory.fromString(map['category']);

    return LogModel(
      id: (map['_id']),
      title: map['title'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      category: category,
      authorId: map["authorId"] ?? "unknown user",
      teamId: map["teamId"] ?? "unknown team",
      synced: map["synced"] ?? false,
      pendingDelete: map["pendingDelete"] ?? false,
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId().oid,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'category': category.name,
      "authorId": authorId,
      "teamId": teamId,
      "synced": true,
      "pendingDelete": false,
    };
  }
}
