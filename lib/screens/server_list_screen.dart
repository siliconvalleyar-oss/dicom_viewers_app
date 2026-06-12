import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../services/orthanc_service.dart';
import '../services/connection_monitor.dart';
import '../services/server_manager.dart';
import '../widgets/connection_log_view.dart';
import '../widgets/edit_server_dialog.dart';
import 'orthanc_browser.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ServerManager>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        centerTitle: true,
      ),
      body: !manager.loaded
          ? const Center(child: CircularProgressIndicator())
          : manager.servers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dns_outlined,
                          size: 64, color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text('No servers configured',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: manager.servers.length,
                  itemBuilder: (_, i) => _ServerTile(
                    server: manager.servers[i],
                    onConnect: () => _connect(context, manager.servers[i]),
                    onEdit: () => _edit(context, manager.servers[i]),
                    onDelete: () => _delete(context, manager, i),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_server',
        onPressed: () => _add(context),
        tooltip: 'Add server',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _connect(BuildContext context, SavedServer server) async {
    final monitor = ConnectionMonitor();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: monitor,
        child: _ConnectionTestDialog(
          server: server,
          monitor: monitor,
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final result = await showDialog<SavedServer>(
      context: context,
      builder: (_) => const EditServerDialog(),
    );
    if (result != null && context.mounted) {
      context.read<ServerManager>().add(result);
    }
  }

  Future<void> _edit(BuildContext context, SavedServer server) async {
    final result = await showDialog<SavedServer>(
      context: context,
      builder: (_) => EditServerDialog(server: server),
    );
    if (result != null && context.mounted) {
      context.read<ServerManager>().update(server.id, result);
    }
  }

  Future<void> _delete(
      BuildContext context, ServerManager manager, int i) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete server'),
        content: Text('Remove "${manager.servers[i].label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      manager.delete(manager.servers[i].id);
    }
  }
}

class _ConnectionTestDialog extends StatefulWidget {
  final SavedServer server;
  final ConnectionMonitor monitor;

  const _ConnectionTestDialog({
    required this.server,
    required this.monitor,
  });

  @override
  State<_ConnectionTestDialog> createState() => _ConnectionTestDialogState();
}

class _ConnectionTestDialogState extends State<_ConnectionTestDialog> {
  bool _success = false;
  bool _running = false;
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() => _running = true);
    widget.monitor.clear();
    final config = widget.server.toConfig();
    final service = OrthancService(config, monitor: widget.monitor);
    _success = await service.testConnection();
    if (mounted) setState(() => _running = false);
  }

  void _copyLog() {
    Clipboard.setData(ClipboardData(text: widget.monitor.fullLog));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLog() {
    Share.share(widget.monitor.fullLog, subject: 'Connection log - ${widget.server.label}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.server.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_running)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: theme.colorScheme.primary),
            ),
          if (!_running) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _debugMode = !_debugMode),
              visualDensity: VisualDensity.compact,
              tooltip: 'Toggle debug mode',
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: _debugMode ? 500 : 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.dns, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.server.host}:${widget.server.port}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                            _debugMode ? widget.server.username : 'tap to connect',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                  if (!_running)
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : theme.colorScheme.error,
                    ),
                ],
              ),
            ),
            if (_debugMode) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  _SmallButton(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: _copyLog,
                  ),
                  const SizedBox(width: 4),
                  _SmallButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: _shareLog,
                  ),
                  const SizedBox(width: 4),
                  _SmallButton(
                    icon: Icons.refresh,
                    label: 'Retest',
                    onTap: _running ? null : _runTest,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Expanded(child: ConnectionLogView()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_success)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final service =
                  OrthancService(widget.server.toConfig());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrthancBrowser(
                      service: service, label: widget.server.label),
                ),
              );
            },
            icon: const Icon(Icons.cloud_done),
            label: const Text('Connect'),
          ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final SavedServer server;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServerTile({
    required this.server,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.dns, color: theme.colorScheme.primary),
        ),
        title: Text(server.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${server.host}:${server.port}',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onConnect,
      ),
    );
  }
}
