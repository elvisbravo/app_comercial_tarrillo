import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _current = true;
  bool _initialized = false;

  bool get current => _current;
  Stream<bool> get isOnline => _controller.stream;

  Future<void> start() async {
    if (_initialized) return;
    _initialized = true;
    final initial = await _connectivity.checkConnectivity();
    _update(_isOnline(initial));
    _connectivity.onConnectivityChanged.listen((results) {
      _update(_isOnline(results));
    });
  }

  bool _isOnline(dynamic results) {
    if (results is List<ConnectivityResult>) {
      return results.any((r) => r != ConnectivityResult.none);
    }
    if (results is ConnectivityResult) {
      return results != ConnectivityResult.none;
    }
    return true;
  }

  void _update(bool value) {
    if (_current == value) return;
    _current = value;
    _controller.add(value);
  }
}
