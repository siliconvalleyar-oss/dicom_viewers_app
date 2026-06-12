import 'package:flutter/material.dart';
import '../services/orthanc_service.dart';

class OrthancConfigDialog extends StatefulWidget {
  final OrthancConfig config;

  const OrthancConfigDialog({super.key, required this.config});

  @override
  State<OrthancConfigDialog> createState() => _OrthancConfigDialogState();
}

class _OrthancConfigDialogState extends State<OrthancConfigDialog> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  bool _testing = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: widget.config.host);
    _portCtrl = TextEditingController(text: widget.config.port.toString());
    _userCtrl = TextEditingController(text: widget.config.username);
    _passCtrl = TextEditingController(text: widget.config.password);
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    final config = OrthancConfig(
      host: _hostCtrl.text,
      port: int.tryParse(_portCtrl.text) ?? 8042,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );
    final service = OrthancService(config);
    final ok = await service.testConnection();
    if (mounted) setState(() { _testing = false; _testResult = ok; });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Orthanc Server'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portCtrl,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8042',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'orthanc',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'orthanc',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _testResult == true
                            ? Icons.check_circle
                            : _testResult == false
                                ? Icons.error
                                : Icons.wifi_find,
                        color: _testResult == true
                            ? Colors.green
                            : _testResult == false
                                ? Colors.red
                                : null,
                      ),
                label: Text(_testing ? 'Testing...' : 'Test Connection'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final config = OrthancConfig(
              host: _hostCtrl.text,
              port: int.tryParse(_portCtrl.text) ?? 8042,
              username: _userCtrl.text,
              password: _passCtrl.text,
            );
            Navigator.pop(context, config);
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
