import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../services/cloud_sync_service.dart';

class CloudSyncIndicator extends StatelessWidget {
  const CloudSyncIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    return StreamBuilder<SyncStatus>(
      stream: projectProvider.syncStatusStream,
      builder: (context, snapshot) {
        // Default status (no data yet)
        Widget icon = const Icon(
          CupertinoIcons.cloud,
          color: CupertinoColors.systemGrey,
        );
        String tooltip = 'iCloud-Status';

        // Update based on sync status
        if (snapshot.hasData) {
          final status = snapshot.data!;

          switch (status.status) {
            case SyncStatusType.syncing:
              icon = const SizedBox(
                width: 20,
                height: 20,
                child: CupertinoActivityIndicator(),
              );
              tooltip = 'Synchronisierung läuft...';
              break;

            case SyncStatusType.synced:
              icon = const Icon(
                CupertinoIcons.cloud_download,
                color: CupertinoColors.activeGreen,
              );
              final timeString = _formatSyncTime(status.timestamp);
              tooltip = 'Letzte Synchronisierung: $timeString';
              break;

            case SyncStatusType.error:
              icon = const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: CupertinoColors.systemRed,
              );
              tooltip = 'Synchronisierungsfehler: ${status.message}';
              break;
          }
        }

        return GestureDetector(
          onTap: () => _showSyncOptions(context, projectProvider),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: icon,
            ),
          ),
        );
      },
    );
  }

  String _formatSyncTime(DateTime? timestamp) {
    if (timestamp == null) return 'Nie';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'Vor $minutes ${minutes == 1 ? 'Minute' : 'Minuten'}';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'Vor $hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute < 10 ? '0' : ''}${timestamp.minute}';
    }
  }

  void _showSyncOptions(BuildContext context, ProjectProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('iCloud-Synchronisierung'),
        message: const Text(
            'Ihre Projekte werden automatisch mit iCloud synchronisiert, ' +
                'solange Sie bei iCloud angemeldet sind.'
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              provider.synchronize();
            },
            child: const Text('Jetzt synchronisieren'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ),
    );
  }
}