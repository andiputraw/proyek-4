import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LogController(username: widget.username);
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

  void _showAddLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Agar dialog tidak memenuhi layar
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul Catatan"),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Isi Deskripsi"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup tanpa simpan
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Jalankan fungsi tambah di Controller
              _controller.addLog(
                _titleController.text,
                _contentController.text,
              );

              // Trigger UI Refresh
              setState(() {});

              // Bersihkan input dan tutup dialog
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _contentController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.updateLog(
                index,
                _titleController.text,
                _contentController.text,
              );
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logbook versi SRP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => {_handleLogout()},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog, // Panggil fungsi dialog yang baru dibuat
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.filteredLogs,
        builder: (context, currentLogs, child) {
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

                    return ListView.builder(
                      itemCount: currentLogs.length,
                      itemBuilder: (context, index) {
                        final log = currentLogs[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.note),
                            title: Text(log.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${log.description}"),
                                Text(
                                  "${log.date.substring(0, 19)}",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showEditLogDialog(index, log),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _controller.removeLog(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
