import 'package:flutter/cupertino.dart';
import 'package:project_hive_backend/sync/project_sync.dart';

class CloudSyncIndicator extends StatelessWidget {
  const CloudSyncIndicator({super.key, required this.syncService});

  final ProjectSyncService syncService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: syncService.syncUpdates,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }

        final status = snapshot.data!;
        late final Icon icon;

        switch (status) {
          case SyncStatus.initial:
            icon = const Icon(
              CupertinoIcons.cloud,
              color: CupertinoColors.systemGrey,
            );
            break;

          case SyncStatus.syncing:
            icon = const Icon(
              CupertinoIcons.arrow_2_circlepath,
              color: CupertinoColors.activeBlue,
            );
            break;

          case SyncStatus.synced:
            icon = const Icon(
              CupertinoIcons.check_mark_circled,
              color: CupertinoColors.activeGreen,
            );
            break;
        }

        return GestureDetector(
          onTap: () => _showSyncOptions(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: icon,
          ),
        );
      },
    );
  }

  void _showSyncOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('iCloud-Synchronisierung'),
        message: const Text(
            'Ihre Projekte werden automatisch mit iCloud synchronisiert, '
            'solange Sie bei iCloud angemeldet sind.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              syncService.sync();
              Navigator.of(context).pop();
            },
            child: const Text('Jetzt synchronisieren'),
          ),
        ],
      ),
    );
  }
}
