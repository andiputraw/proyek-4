import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/auth/model/login_data.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final LoginData currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final ValueNotifier<LogCategory> _selectedCategory = ValueNotifier(
    LogCategory.pekerjaan,
  );

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );

    _selectedCategory.value = widget.log?.category ?? LogCategory.pekerjaan;

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (widget.log == null) {
      // Tambah Baru
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        widget.currentUser.id,
        widget.currentUser.teamId,
        _selectedCategory.value,
      );
    } else {
      // Update
      widget.controller.updateLog(
        widget.index!,
        _titleController.text,
        _descController.text,

        widget.currentUser.id,
        widget.currentUser.teamId,
        _selectedCategory.value,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsetsGeometry.all(10),
                    child: ValueListenableBuilder(
                      valueListenable: _selectedCategory,
                      builder:
                          (
                            BuildContext context,
                            LogCategory currentStatus,
                            Widget? child,
                          ) {
                            return DropdownMenu<LogCategory>(
                              initialSelection: currentStatus,
                              label: const Text("Kategori"),
                              onSelected: (LogCategory? category) {
                                _selectedCategory.value =
                                    category ?? LogCategory.pekerjaan;
                              },
                              dropdownMenuEntries: LogCategory.values
                                  .map(
                                    (category) => DropdownMenuEntry(
                                      value: category,
                                      label: category.name,
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}
