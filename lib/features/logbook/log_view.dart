import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_001/features/auth/model/login_data.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LogView extends StatefulWidget {
  final LoginData currentUser;
  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<LogCategory> _selectedCategory = ValueNotifier(
    LogCategory.pekerjaan,
  );
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isLoading = false;
  final ValueNotifier<bool> _isOffline = ValueNotifier(true);

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _selectedCategory.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      username: widget.currentUser.username,
      currentUser: widget.currentUser,
    );

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      final isPreviousOffline = _isOffline.value;

      _isOffline.value = result.contains(ConnectivityResult.none);
      LogHelper.writeLog("INFO: Status $_isOffline.value", level: 2);
      if (_isOffline.value) {
        _showConnectivityBanner();
      }

      if (!_isLoading && isPreviousOffline && !_isOffline.value) {
        Future.microtask(() => _controller.syncData());
        if (mounted) {
          ScaffoldMessenger.of(context).clearMaterialBanners();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kembali terkoneksi internet."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await _controller.init();
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: "log_view.dart",
      );

      // Mengaktifkan kembali koneksi dengan timeout 15 detik (lebih longgar untuk sinyal HP)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Mengambil data log dari Cloud
      await LogHelper.writeLog(
        "UI: Memanggil controller.loadFromDisk()...",
        source: "log_view.dart",
      );

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );
    } finally {
      // 2. INILAH FINALLY: Apapun yang terjadi (Sukses/Gagal/Data Kosong), loading harus mati
      if (mounted) {
        setState(() => _isLoading = false);
      }
      await _controller.loadFromDisk();
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _showConnectivityBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text('No internet connection.'),
        leading: const Icon(Icons.wifi_off),
        backgroundColor: Colors.red,
        actions: [
          TextButton(
            onPressed: () {
              // You must manually hide banners!
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text(
            "Apakah Anda yakin? Data yang belum disimpan mungkin hilang",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingView(),
                    ),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil Logout")),
                  );
                });
              },
              child: const Text("Ya, keluar"),
            ),
          ],
        );
      },
    );
  }

  static Color colorFromCategory(LogCategory category) {
    return switch (category) {
      LogCategory.pekerjaan => Color.fromARGB(255, 124, 235, 152),
      LogCategory.pribadi => Color.fromARGB(255, 130, 236, 250),
      LogCategory.urgent => Color.fromARGB(255, 240, 117, 108),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Logbook: ${widget.currentUser.username} |  ${widget.currentUser.role} ",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => {_handleLogout()},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _goToEditor(), // Panggil fungsi dialog yang baru dibuat
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.filteredLogs,
        builder: (context, currentLogs, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke MongoDB Atlas..."),
                ],
              ),
            );
          }
          // 2. Tampilan jika loading sudah selesai tapi data di Atlas kosong
          if (currentLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Belum ada catatan di Cloud."),
                  ElevatedButton(
                    onPressed: () => _goToEditor(),
                    child: const Text("Buat Catatan Pertama"),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _controller.searchLog(value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (context, v, child) {
                    if (currentLogs.isEmpty) {
                      return Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/question.png",
                              width: 300,
                            ),
                            Text("Catatan tidak ditemukan."),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _controller.loadFromDisk,
                      color: Colors.lightBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ), // Jarak di luar list
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) {
                          final log = currentLogs[index];

                          return Card(
                            elevation: 2, // Memberikan sedikit bayangan
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ), // Jarak antar card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // Sudut membulat modern
                            ),
                            color: colorFromCategory(log.category),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- BARIS 1: TAG KATEGORI & STATUS CLOUD ---
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Tag Kategori
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(
                                            0.6,
                                          ), // Transparan agar menyatu dengan warna background
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          log.category.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),

                                      // Tag Status Sync Cloud
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: log.synced
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: log.synced
                                                ? Colors.green
                                                : Colors.orange,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              log.synced
                                                  ? Icons.cloud_done
                                                  : Icons.cloud_upload,
                                              size: 14,
                                              color: log.synced
                                                  ? Colors.green[800]
                                                  : Colors.orange[800],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              log.synced
                                                  ? "Synced"
                                                  : "Pending Sync",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: log.synced
                                                    ? Colors.green[800]
                                                    : Colors.orange[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // --- BARIS 2: JUDUL & TANGGAL ---
                                  Text(
                                    log.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy • HH:mm',
                                        ).format(log.date),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // --- BARIS 3: TOMBOL AKSI ---
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (AccessControlService.canPerform(
                                        widget.currentUser.role,
                                        AccessControlService.actionUpdate,
                                        isOwner:
                                            widget.currentUser.id ==
                                            log.authorId,
                                      ))
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_note,
                                            color: Colors.blueAccent,
                                          ),
                                          tooltip: "Edit Log",
                                          onPressed: () => _goToEditor(
                                            log: log,
                                            index: index,
                                          ),
                                        ),
                                      if (AccessControlService.canPerform(
                                        widget.currentUser.role,
                                        AccessControlService.actionDelete,
                                        isOwner:
                                            widget.currentUser.id ==
                                            log.authorId,
                                      ))
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: "Hapus Log",
                                          onPressed: () =>
                                              _controller.removeLog(index),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
