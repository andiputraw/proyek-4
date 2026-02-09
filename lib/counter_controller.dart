class CounterController {
  int step = 1;
  int _counter = 0;
  int get value => _counter;

  void increment() {
    _counter += step;
  }

  void decrement() {
    if (_counter > 0) {
      _counter -= step;
    }
  }

  void reset() {
    _counter = 0;
  }
}
