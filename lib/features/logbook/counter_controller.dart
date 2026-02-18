import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int step = 1;
  int _counter = 0;
  int get value => _counter;
  String _username = "";
  Queue<String> _history = Queue();
  List<String> get history => _history.toList();

  static Future<CounterController> init(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    int? counter = prefs.getInt(_buildCounterKey(username));
    List<String>? logging = prefs.getStringList(_buildLogsKey(username));

    return CounterController(
      initialValue: counter ?? 0,
      initialLogging: logging ?? [],
      username: username,
    );
  }

  CounterController({
    required int initialValue,
    required List<String> initialLogging,
    required String username,
  }) {
    _counter = initialValue;
    _username = username;
    _history = Queue.from(initialLogging);
  }

  static String _buildCounterKey(String username) {
    return "$username-counter";
  }

  static String _buildLogsKey(String username) {
    return "$username-logs";
  }

  Future<void> saveCounter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_buildCounterKey(_username), value);
    await prefs.setStringList(_buildLogsKey(_username), history);
    print("Counter saved $value");
  }

  void increment() {
    _counter += step;
    pushHistory("+$step : ${now()}");
  }

  void decrement() {
    if (_counter > 0) {
      _counter -= step;
      if (_counter < 0) _counter = 0;
      pushHistory("-$step : ${now()}");
    }
  }

  void reset() {
    _counter = 0;
    pushHistory("reset : ${now()}");
  }

  void pushHistory(String str) async {
    if (_history.length >= 5) {
      _history.removeFirst();
    }
    _history.addLast(str);
    await saveCounter();
  }

  String now() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-mm-dd hh:mm').format(now);
  }
}
