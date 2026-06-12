import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/orthanc_service.dart';
import '../services/connection_monitor.dart';
import '../services/server_manager.dart';
import 'connection_log_view.dart';

class EditServerDialog extends StatefulWidget {
  final SavedServer? server;

  const EditServerDialog({super.key, this.server});

  @override
  State<EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<EditServerDialog> {
  late TextEditingController _labelCtrl;
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  final ConnectionMonitor _monitor = ConnectionMonitor();

  bool get _editing => widget.server != null;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _labelCtrl = TextEditingController(text: s?.label ?? '');
    _hostCtrl = TextEditingController(text: s?.host ?? '192.168.1.44');
    _portCtrl = TextEditingController(text: (s?.port ?? 8042).toString());
    _userCtrl = TextEditingController(text: s?.username ?? 'orthanc');
    _passCtrl = TextEditingController(text: s?.password ?? 'orthanc');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _monitor.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final config = OrthancConfig(
      host: _hostCtrl.text,
      port: int.tryParse(_portCtrl.text) ?? 8042,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );
    final service = OrthancService(config, monitor: _monitor);
    await service.testConnection();
  }

  void _showLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: _monitor,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: ConnectionLogView(),
        ),
      ),
    );
  }

  SavedServer _buildServer() {
    final id = widget.server?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return SavedServer(
      id: id,
      label: _labelCtrl.text.isEmpty ? _hostCtrl.text : _labelCtrl.text,
      host: _hostCtrl.text,
      port: int.tryParse(_portCtrl.text) ?? 8042,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit Server' : 'Add Server'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Hospital principal',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'Host / IP',
                hintText: '192.168.1.44 or raspberry.local',
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
            OutlinedButton.icon(
              onPressed: _testConnection,
              icon: _monitor.running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_monitor.running ? 'Testing...' : 'Test Connection'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _monitor.logs.isEmpty ? null : _showLog,
              child: const Text('View connection log'),
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
          onPressed: () => Navigator.pop(context, _buildServer()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
