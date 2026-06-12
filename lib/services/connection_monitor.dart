import 'package:flutter/foundation.dart';

class ConnectionLog {
  final DateTime time;
  final String message;
  final bool isError;

  ConnectionLog(this.message, {this.isError = false})
      : time = DateTime.now();
}

class ConnectionMonitor extends ChangeNotifier {
  final List<ConnectionLog> _logs = [];
  bool _running = false;

  List<ConnectionLog> get logs => List.unmodifiable(_logs);
  bool get running => _running;

  void start() {
    _logs.clear();
    _running = true;
    _logs.add(ConnectionLog('Starting connection...'));
    notifyListeners();
  }

  void log(String message) {
    _logs.add(ConnectionLog(message));
    notifyListeners();
  }

  void error(String message) {
    _logs.add(ConnectionLog(message, isError: true));
    notifyListeners();
  }

  void done() {
    _running = false;
    notifyListeners();
  }

  void stop() {
    _running = false;
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  String get fullLog {
    final buf = StringBuffer();
    for (final log in _logs) {
      final t =
          '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}.${log.time.millisecond.toString().padLeft(3, '0')}';
      buf.writeln('$t ${log.isError ? "[ERROR]" : "      "} ${log.message}');
    }
    return buf.toString();
  }
}
