import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logbook versi SRP")),
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ),
    );
  }
}
