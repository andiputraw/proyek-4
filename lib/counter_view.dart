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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Total hitungan"),
                Text(
                  "${_controller.value}",
                  style: const TextStyle(fontSize: 40),
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
              ],
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
