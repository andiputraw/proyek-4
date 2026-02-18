import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late CounterController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _setupController();
  }

  Future<void> _setupController() async {
    _controller = await CounterController.init(widget.username);
    setState(() => _isLoading = false);
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset hitungan"),
          content: const Text(
            "Aksi ini akan me-reset hitungan kembali menjadi 0",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Counter berhasil di reset")),
                  );
                  _controller.reset();
                });
              },
              child: const Text("Lanjutkan"),
            ),
          ],
        );
      },
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
                  _controller.reset();
                });
              },
              child: const Text("Ya, keluar"),
            ),
          ],
        );
      },
    );
  }

  void _handleSave() {
    _controller.saveCounter().then((value) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Berhasil Menyimpan")));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        child: Icon(Icons.save),
        onPressed: () => {_handleSave()},
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Selamat ${DateTime.now().hour < 12
                    ? 'Pagi'
                    : DateTime.now().hour < 18
                    ? 'Malam'
                    : 'Siang'} ${widget.username}",
              ),
            ),
            const Center(child: Text("Total hitungan")),
            Center(
              child: Text(
                "${_controller.value}",
                style: const TextStyle(fontSize: 40),
              ),
            ),
            Row(
              children: [
                Text("Step: ${_controller.step}"),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 100,
                    value: _controller.step.toDouble(),
                    onChanged: (v) =>
                        setState(() => _controller.step = v.toInt()),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,

              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _controller.increment()),
                  style: ButtonStyle(),
                  child: Text("Tambah"),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _controller.decrement()),
                  style: ButtonStyle(),
                  child: Text("Kurang"),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _showResetDialog(context)),
                  style: ButtonStyle(),
                  child: Text("Reset"),
                ),
              ],
            ),
            Center(
              child: const Text(
                "History",
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.history.length > 5
                    ? 5
                    : _controller.history.length,
                itemBuilder: (BuildContext context, int index) {
                  Color textColor = switch (_controller.history[index][0]) {
                    '-' => Color.fromRGBO(255, 0, 0, 1.0),
                    '+' => Color(0xff4d9900),
                    _ => Color.fromRGBO(0, 0, 0, 1.0),
                  };

                  return Text(
                    _controller.history[index],
                    style: TextStyle(color: textColor),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.0, vertical: 20.0),
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Change color based on current index
                    color: 2 == index ? Colors.blue : Colors.grey,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
