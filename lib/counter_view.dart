import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logbook versi SRP")),
      body: Center(
        child: Column(
          children: [
            const Text("Total hitungan"),
            Text("${_controller.value}", style: const TextStyle(fontSize: 40)),
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  onPressed: () => setState(() => _controller.reset()),
                  style: ButtonStyle(),
                  child: Text("Reset"),
                ),
              ],
            ),
            const Text(
              "History",
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.history.length > 5
                    ? 5
                    : _controller.history.length,
                itemBuilder: (BuildContext context, int index) {
                  return Text(_controller.history[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _controller.increment()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
