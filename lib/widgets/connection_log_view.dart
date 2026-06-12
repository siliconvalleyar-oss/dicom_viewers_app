import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../services/connection_monitor.dart';

class ConnectionLogView extends StatelessWidget {
  const ConnectionLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final mon = context.watch<ConnectionMonitor>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (mon.running)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Icon(Icons.check_circle_outline,
                    size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Text(
                mon.running ? 'Running test...' : 'Test results',
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              if (mon.logs.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: mon.fullLog));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy log',
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 16),
                  onPressed: () {
                    Share.share(mon.fullLog, subject: 'Connection log');
                  },
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Share log',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () => context.read<ConnectionMonitor>().clear(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Clear log',
                ),
              ],
            ],
          ),
          const Divider(height: 4),
          Expanded(
            child: mon.logs.isEmpty
                ? Center(
                    child: Text('Running...',
                        style: theme.textTheme.bodySmall),
                  )
                : ListView.builder(
                    itemCount: mon.logs.length,
                    itemBuilder: (_, i) {
                      final log = mon.logs[i];
                      final t =
                          '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}.${log.time.millisecond.toString().padLeft(3, '0')}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.outline,
                                )),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                log.message,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: log.isError
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
