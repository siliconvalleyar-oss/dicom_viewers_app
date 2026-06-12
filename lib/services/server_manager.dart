import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'orthanc_service.dart';

class SavedServer {
  String id;
  String label;
  String host;
  int port;
  String username;
  String password;
  bool useTls;

  SavedServer({
    required this.id,
    this.label = '',
    this.host = '192.168.1.44',
    this.port = 8042,
    this.username = 'orthanc',
    this.password = 'orthanc',
    this.useTls = false,
  });

  OrthancConfig toConfig() => OrthancConfig(
        host: host,
        port: port,
        username: username,
        password: password,
        useTls: useTls,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'useTls': useTls,
      };

  factory SavedServer.fromJson(Map<String, dynamic> json) => SavedServer(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        host: json['host'] as String? ?? '192.168.1.44',
        port: json['port'] as int? ?? 8042,
        username: json['username'] as String? ?? 'orthanc',
        password: json['password'] as String? ?? 'orthanc',
        useTls: json['useTls'] as bool? ?? false,
      );
}

class ServerManager extends ChangeNotifier {
  List<SavedServer> _servers = [];
  bool _loaded = false;

  List<SavedServer> get servers => _servers;
  bool get loaded => _loaded;

  static const _key = 'orthanc_servers';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _servers = list
          .map((e) => SavedServer.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (_servers.isEmpty) {
      _servers.addAll([
        SavedServer(
          id: 'default-ip',
          label: 'Servidor IP',
          host: '192.168.1.44',
        ),
        SavedServer(
          id: 'default-mdns',
          label: 'Raspberry local',
          host: 'raspberry.local',
        ),
      ]);
      await _save();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(SavedServer server) async {
    _servers.add(server);
    await _save();
    notifyListeners();
  }

  Future<void> update(String id, SavedServer updated) async {
    final idx = _servers.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _servers[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _servers.removeWhere((s) => s.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_servers.map((s) => s.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
