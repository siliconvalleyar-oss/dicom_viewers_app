import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'connection_monitor.dart';

class OrthancConfig {
  String host;
  int port;
  String username;
  String password;
  bool useTls;

  OrthancConfig({
    this.host = '192.168.1.44',
    this.port = 8042,
    this.username = 'orthanc',
    this.password = 'orthanc',
    this.useTls = false,
  });

  String get baseUrl =>
      '${useTls ? "https" : "http"}://$host:$port';

  Map<String, String> get authHeaders {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }
}

class OrthancPatient {
  final String id;
  final String? name;
  final String? patientId;
  final String? birthDate;
  final String? sex;

  OrthancPatient({
    required this.id,
    this.name,
    this.patientId,
    this.birthDate,
    this.sex,
  });

  factory OrthancPatient.fromJson(String id, Map<String, dynamic> json) {
    final tags = json['MainDicomTags'] as Map<String, dynamic>?;
    return OrthancPatient(
      id: id,
      name: tags?['PatientName']?.toString(),
      patientId: tags?['PatientID']?.toString(),
      birthDate: tags?['PatientBirthDate']?.toString(),
      sex: tags?['PatientSex']?.toString(),
    );
  }
}

class OrthancStudy {
  final String id;
  final String? description;
  final String? date;
  final String? accessionNumber;
  final int seriesCount;

  OrthancStudy({
    required this.id,
    this.description,
    this.date,
    this.accessionNumber,
    required this.seriesCount,
  });

  factory OrthancStudy.fromJson(String id, Map<String, dynamic> json) {
    final tags = json['MainDicomTags'] as Map<String, dynamic>?;
    return OrthancStudy(
      id: id,
      description: tags?['StudyDescription']?.toString(),
      date: tags?['StudyDate']?.toString(),
      accessionNumber: tags?['AccessionNumber']?.toString(),
      seriesCount: (json['Series'] as List?)?.length ?? 0,
    );
  }
}

class OrthancSeries {
  final String id;
  final String? modality;
  final String? description;
  final String? seriesNumber;
  final int instanceCount;

  OrthancSeries({
    required this.id,
    this.modality,
    this.description,
    this.seriesNumber,
    required this.instanceCount,
  });

  factory OrthancSeries.fromJson(String id, Map<String, dynamic> json) {
    final tags = json['MainDicomTags'] as Map<String, dynamic>?;
    return OrthancSeries(
      id: id,
      modality: tags?['Modality']?.toString(),
      description: tags?['SeriesDescription']?.toString(),
      seriesNumber: tags?['SeriesNumber']?.toString(),
      instanceCount: (json['Instances'] as List?)?.length ?? 0,
    );
  }
}

class OrthancInstance {
  final String id;
  final int? instanceNumber;

  OrthancInstance({required this.id, this.instanceNumber});

  factory OrthancInstance.fromJson(String id, Map<String, dynamic> json) {
    final tags = json['MainDicomTags'] as Map<String, dynamic>?;
    return OrthancInstance(
      id: id,
      instanceNumber: int.tryParse(tags?['InstanceNumber']?.toString() ?? ''),
    );
  }
}

class OrthancService {
  OrthancConfig config;
  ConnectionMonitor? monitor;

  OrthancService(this.config, {this.monitor});

  void _log(String msg) => monitor?.log(msg);
  void _err(String msg) => monitor?.error(msg);

  Future<bool> testConnection() async {
    monitor?.start();
    bool ok = false;

    // 1. DNS resolution
    _log('--- Step 1: DNS resolution ---');
    _log('Host: ${config.host}');
    try {
      final start = DateTime.now();
      final addresses = await InternetAddress.lookup(config.host)
          .timeout(const Duration(seconds: 5));
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      _log('DNS resolved in ${elapsed}ms');
      for (final addr in addresses) {
        _log('  → ${addr.address} (${addr.type.name})');
      }
      if (addresses.isEmpty) {
        _err('DNS returned no addresses');
      }
    } on SocketException catch (e) {
      _err('DNS lookup failed: ${e.message}');
      monitor?.done();
      return false;
    } on Exception catch (e) {
      _err('DNS error: $e');
      monitor?.done();
      return false;
    }

    // 2. TCP port connectivity
    _log('');
    _log('--- Step 2: TCP port check ---');
    _log('Connecting to ${config.host}:${config.port}...');
    try {
      final start = DateTime.now();
      final socket = await Socket.connect(
        config.host,
        config.port,
        timeout: const Duration(seconds: 5),
      );
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      _log('TCP connected in ${elapsed}ms');
      _log('Remote: ${socket.remoteAddress.address}:${socket.remotePort}');
      await socket.close();
      _log('TCP connection closed');
    } on SocketException catch (e) {
      _err('TCP connection failed: ${e.message}');
      _err('Port ${config.port} may be closed, blocked, or host unreachable');
      monitor?.done();
      return false;
    } on Exception catch (e) {
      _err('TCP error: $e');
      monitor?.done();
      return false;
    }

    // 3. Ping test
    _log('');
    _log('--- Step 3: Ping test ---');
    try {
      _log('Running ping -c 1 -W 3 ${config.host}');
      final start = DateTime.now();
      final result = await Process.run(
        'ping',
        ['-c', '1', '-W', '3', config.host],
      ).timeout(const Duration(seconds: 10));
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) _log('  $line');
        }
        _log('Ping OK (${elapsed}ms)');
      } else {
        final err = (result.stderr as String).trim();
        _err('Ping failed (exit ${result.exitCode})');
        if (err.isNotEmpty) _err('  $err');
        final out = (result.stdout as String).trim();
        if (out.isNotEmpty) _err('  $out');
      }
    } on Exception catch (e) {
      _err('Ping command not available: $e');
      _log('Falling back to TCP RTT test...');
      try {
        final rttStart = DateTime.now();
        final testSock = await Socket.connect(
          config.host,
          config.port,
          timeout: const Duration(seconds: 4),
        );
        final rtt = DateTime.now().difference(rttStart).inMilliseconds;
        _log('TCP port ${config.port} reachable in ${rtt}ms');
        await testSock.close();
      } on Exception catch (e2) {
        _err('TCP fallback also failed: $e2');
      }
    }

    // 4. Raw HTTP request (like curl)
    _log('');
    _log('--- Step 4: Raw HTTP request (curl) ---');
    try {
      final path = '/system';
      final sock = await Socket.connect(
        config.host,
        config.port,
        timeout: const Duration(seconds: 5),
      );
      final credentials =
          base64Encode(utf8.encode('${config.username}:${config.password}'));
      final request = StringBuffer();
      request.writeln('GET $path HTTP/1.1');
      request.writeln('Host: ${config.host}:${config.port}');
      request.writeln('Authorization: Basic $credentials');
      request.writeln('Accept: application/json');
      request.writeln('Connection: close');
      request.writeln('');
      _log('--- raw request ---');
      for (final line in request.toString().split('\n')) {
        if (line.contains('Authorization:')) {
          _log('Authorization: Basic ${credentials.substring(0, 12)}...');
        } else {
          _log(line.trimRight());
        }
      }
      _log('--- end request ---');

      sock.write(request.toString());
      final bytes = await sock
          .toList()
          .timeout(const Duration(seconds: 8));
      final rawResponse = utf8.decode(bytes.expand((b) => b).toList());

      final lines = rawResponse.split('\r\n');
      if (lines.isNotEmpty) {
        _log('Status: ${lines.first}');
      }
      _log('--- raw response headers ---');
      int i = 1;
      for (; i < lines.length; i++) {
        if (lines[i].isEmpty) break;
        _log(lines[i]);
      }
      _log('--- end headers ---');
      i++;
      if (i < lines.length) {
        final bodyLines = lines.sublist(i).join('\n');
        _log('Body (${bodyLines.length} chars):');
        _log(bodyLines.length > 500
            ? '${bodyLines.substring(0, 500)}...'
            : bodyLines);
      }
      await sock.close();

      if (lines.isNotEmpty && lines.first.contains('200')) {
        ok = true;
        _log('');
        _log('✓ Connection successful!');
      }
    } on SocketException catch (e) {
      _err('Raw HTTP failed: ${e.message}');
    } on Exception catch (e) {
      _err('Raw HTTP error: $e');
    }

    // 5. HTTP package test
    _log('');
    _log('--- Step 5: HTTP package test ---');
    try {
      final uri = Uri.parse('${config.baseUrl}/system');
      _log('GET ${uri.toString()}');

      final start = DateTime.now();
      final response = await http
          .get(uri, headers: config.authHeaders)
          .timeout(const Duration(seconds: 8));
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      _log('Response: ${elapsed}ms, status ${response.statusCode}');
      response.headers.forEach((k, v) {
        if (k != 'authorization') _log('  $k: $v');
      });

      if (response.statusCode == 200) {
        _log('');
        _log('✓ Connection successful!');
        ok = true;
      } else if (response.statusCode == 401) {
        _err('Authentication failed (401)');
        _err('Check username and password');
      } else if (response.statusCode == 404) {
        _err('Endpoint not found (404)');
      } else {
        _err('Unexpected HTTP ${response.statusCode}');
        _err('Body: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      }
    } on SocketException catch (e) {
      _err('HTTP socket error: ${e.message}');
    } on http.ClientException catch (e) {
      _err('HTTP client error: ${e.message}');
    } on FormatException catch (e) {
      _err('Invalid URL format: ${e.message}');
    } on Exception catch (e) {
      _err('HTTP error: $e');
    }

    monitor?.done();
    return ok;
  }

  Future<List<OrthancPatient>> getPatients() async {
    final uri = Uri.parse('${config.baseUrl}/patients');
    final response = await http.get(uri, headers: config.authHeaders);
    if (response.statusCode != 200) return [];

    final ids = List<String>.from(jsonDecode(response.body));
    final patients = <OrthancPatient>[];
    for (final id in ids) {
      final detail = await _getJson('/patients/$id');
      if (detail != null) {
        patients.add(OrthancPatient.fromJson(id, detail));
      }
    }
    return patients;
  }

  Future<List<OrthancStudy>> getStudies(String patientId) async {
    final detail = await _getJson('/patients/$patientId');
    if (detail == null) return [];
    final studyIds = List<String>.from(detail['Studies'] ?? []);
    final studies = <OrthancStudy>[];
    for (final id in studyIds) {
      final studyData = await _getJson('/studies/$id');
      if (studyData != null) {
        studies.add(OrthancStudy.fromJson(id, studyData));
      }
    }
    return studies;
  }

  Future<List<OrthancSeries>> getSeries(String studyId) async {
    final detail = await _getJson('/studies/$studyId');
    if (detail == null) return [];
    final seriesIds = List<String>.from(detail['Series'] ?? []);
    final series = <OrthancSeries>[];
    for (final id in seriesIds) {
      final seriesData = await _getJson('/series/$id');
      if (seriesData != null) {
        series.add(OrthancSeries.fromJson(id, seriesData));
      }
    }
    return series;
  }

  Future<List<OrthancInstance>> getInstances(String seriesId) async {
    final detail = await _getJson('/series/$seriesId');
    if (detail == null) return [];
    final instanceIds = List<String>.from(detail['Instances'] ?? []);
    final instances = <OrthancInstance>[];
    for (final id in instanceIds) {
      final instanceData = await _getJson('/instances/$id');
      if (instanceData != null) {
        instances.add(OrthancInstance.fromJson(id, instanceData));
      }
    }
    return instances;
  }

  Future<Uint8List?> getPreview(String instanceId) async {
    final uri = Uri.parse('${config.baseUrl}/instances/$instanceId/preview');
    try {
      final response = await http.get(uri, headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      });
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  Future<Uint8List?> getDicomFile(String instanceId) async {
    final uri = Uri.parse('${config.baseUrl}/instances/$instanceId/file');
    try {
      final response = await http.get(uri, headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      });
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _getJson(String path) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    try {
      final response = await http.get(uri, headers: config.authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
