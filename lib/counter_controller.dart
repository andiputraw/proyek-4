import 'dart:collection';

import 'package:intl/intl.dart';

class CounterController {
  int step = 1;
  int _counter = 0;
  int get value => _counter;
  final Queue<String> _history = Queue();
  List<String> get history => _history.toList();

  void increment() {
    _counter += step;
    pushHistory("+$step : ${now()}");
  }

  void decrement() {
    if (_counter > 0) {
      _counter -= step;
      pushHistory("-$step : ${now()}");
    }
  }

  void reset() {
    _counter = 0;
    pushHistory("reset : ${now()}");
  }

  void pushHistory(String str) {
    if (_history.length >= 5) {
      _history.removeFirst();
    }
    _history.addLast(str);
  }

  String now() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-mm-dd hh:mm').format(now);
  }
}
