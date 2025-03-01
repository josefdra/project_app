import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:icloud_storage/icloud_storage.dart';

import '../providers/project_provider.dart';
import '../services/backup_service.dart';
import '../services/icloud_service.dart';
import '../services/google_drive_service.dart';

/// Manages all backup functionality with platform-specific implementations
class BackupManager {
  final BackupService _backupService = BackupService();
  final ICloudBackupService _iCloudService = ICloudBackupService();
  final GoogleDriveBackupService _googleDriveService = GoogleDriveBackupService();

  bool _isIOS() => Platform.isIOS;
  bool _isAndroid() => Platform.isAndroid;

  /// Create a manual backup
  Future<void> createManualBackup(BuildContext context) async {
    try {
      await _backupService.shareBackup();
    } catch (e) {
      _showErrorDialog(context, 'Could not create backup: $e');
    }
  }

  /// Create a cloud backup
  Future<bool> createCloudBackup(BuildContext context) async {
    try {
      final backupFile = await _backupService.createBackupFile();

      if (_isIOS()) {
        final success = await _iCloudService.uploadBackupToICloud(backupFile);
        if (success) {
          _showSuccessDialog(context, 'Backup saved to iCloud');
          return true;
        } else {
          _showErrorDialog(context, 'Could not save to iCloud');
          return false;
        }
      } else if (_isAndroid()) {
        final success = await _googleDriveService.uploadBackupToGoogleDrive(backupFile);
        if (success) {
          _showSuccessDialog(context, 'Backup saved to Google Drive');
          return true;
        } else {
          _showErrorDialog(context, 'Could not save to Google Drive');
          return false;
        }
      }

      return false;
    } catch (e) {
      _showErrorDialog(context, 'Error creating cloud backup: $e');
      return false;
    }
  }

  /// Show the backup screen
  void showBackupScreen(BuildContext context) {
    if (_isIOS()) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => BackupScreen(manager: this),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BackupScreen(manager: this),
        ),
      );
    }
  }

  /// Check if cloud backup is available
  Future<bool> isCloudBackupAvailable() async {
    if (_isIOS()) {
      return await _iCloudService.isICloudAvailable();
    } else if (_isAndroid()) {
      return await _googleDriveService.isSignedIn();
    }
    return false;
  }

  /// Get last backup date (local)
  Future<DateTime?> getLastBackupDate() {
    return _backupService.getLastBackupDate();
  }

  /// Get last cloud backup date
  Future<DateTime?> getLastCloudBackupDate() async {
    if (_isIOS()) {
      return await _iCloudService.getLastICloudBackupDate();
    } else if (_isAndroid()) {
      return await _googleDriveService.getLastGoogleDriveBackupDate();
    }
    return null;
  }

  /// List available cloud backups
  Future<List<dynamic>> listCloudBackups() async {
    if (_isIOS()) {
      return await _iCloudService.listICloudBackups();
    } else if (_isAndroid()) {
      return await _googleDriveService.listGoogleDriveBackups();
    }
    return [];
  }

  /// List available local backups
  Future<List<FileSystemEntity>> listLocalBackups() {
    return _backupService.listBackups();
  }

  /// Restore from cloud backup
  Future<bool> restoreFromCloudBackup(BuildContext context, dynamic backupItem) async {
    try {
      File? localFile;

      if (_isIOS()) {
        localFile = await _iCloudService.downloadBackupFromICloud(backupItem as ICloudFile);
      } else if (_isAndroid()) {
        localFile = await _googleDriveService.downloadBackupFromGoogleDrive(backupItem as drive.File);
      }

      if (localFile == null) {
        _showErrorDialog(context, 'Could not download backup');
        return false;
      }

      final result = await _backupService.restoreFromFile(localFile);

      if (result) {
        // Refresh the provider
        Provider.of<ProjectProvider>(context, listen: false).refreshData();

        _showSuccessDialog(context, 'Backup restored successfully');
        return true;
      } else {
        _showErrorDialog(context, 'Error restoring backup');
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, 'Error restoring from cloud: $e');
      return false;
    }
  }

  /// Restore from local backup
  Future<bool> restoreFromLocalBackup(BuildContext context, File backupFile) async {
    try {
      final result = await _backupService.restoreFromFile(backupFile);

      if (result) {
        // Refresh the provider
        Provider.of<ProjectProvider>(context, listen: false).refreshData();

        _showSuccessDialog(context, 'Backup restored successfully');
        return true;
      } else {
        _showErrorDialog(context, 'Error restoring backup');
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, 'Error restoring from local file: $e');
      return false;
    }
  }

  /// Log in to cloud service (Android only)
  Future<bool> signInToCloudService() async {
    if (_isAndroid()) {
      return await _googleDriveService.signIn();
    }
    return false;
  }

  /// Log out from cloud service (Android only)
  Future<void> signOutFromCloudService() async {
    if (_isAndroid()) {
      await _googleDriveService.signOut();
    }
  }

  /// Delete a cloud backup
  Future<bool> deleteCloudBackup(dynamic backupItem) async {
    try {
      if (_isIOS()) {
        return await _iCloudService.deleteICloudBackup(backupItem as ICloudFile);
      } else if (_isAndroid()) {
        return await _googleDriveService.deleteGoogleDriveBackup(backupItem as drive.File);
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }

  /// Delete a local backup
  Future<void> deleteLocalBackup(File backupFile) {
    return _backupService.deleteBackup(backupFile);
  }

  // Show success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    if (_isIOS()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    if (_isIOS()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}

/// Backup Screen - User Interface for backup and restore operations
class BackupScreen extends StatefulWidget {
  final BackupManager manager;

  const BackupScreen({
    Key? key,
    required this.manager,
  }) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  bool _isCloudAvailable = false;
  List<dynamic> _cloudBackups = [];
  List<FileSystemEntity> _localBackups = [];
  DateTime? _lastLocalBackup;
  DateTime? _lastCloudBackup;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _isCloudAvailable = await widget.manager.isCloudBackupAvailable();
    _lastLocalBackup = await widget.manager.getLastBackupDate();
    _lastCloudBackup = await widget.manager.getLastCloudBackupDate();

    if (_isCloudAvailable) {
      _cloudBackups = await widget.manager.listCloudBackups();
    }

    _localBackups = await widget.manager.listLocalBackups();

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _getBackupName(dynamic backup) {
    if (backup is File) {
      return backup.path.split('/').last;
    } else if (Platform.isIOS && backup is ICloudFile) {
      return backup.filename;
    } else if (Platform.isAndroid && backup is drive.File) {
      return backup.name ?? 'Unknown';
    }
    return 'Unknown backup';
  }

  DateTime? _getBackupDate(dynamic backup) {
    if (backup is File) {
      return backup.statSync().modified;
    } else if (Platform.isIOS && backup is ICloudFile) {
      return backup.date;
    } else if (Platform.isAndroid && backup is drive.File) {
      return backup.modifiedTime;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoUI();
    } else {
      return _buildMaterialUI();
    }
  }

  Widget _buildCupertinoUI() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Backup & Restore'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackupSection(),
                const SizedBox(height: 24),
                _buildCloudBackupSection(),
                const SizedBox(height: 24),
                _buildLocalBackupSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackupSection(),
              const SizedBox(height: 24),
              _buildCloudBackupSection(),
              const SizedBox(height: 24),
              _buildLocalBackupSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    final theme = Platform.isIOS ? CupertinoTheme.of(context) : Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Backup',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Platform.isIOS
                ? CupertinoColors.label
                : theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Last local backup: ${_formatDateTime(_lastLocalBackup)}',
          style: TextStyle(
            color: Platform.isIOS
                ? CupertinoColors.secondaryLabel
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
        if (_isCloudAvailable) ...[
          const SizedBox(height: 8),
          Text(
            'Last cloud backup: ${_formatDateTime(_lastCloudBackup)}',
            style: TextStyle(
              color: Platform.isIOS
                  ? CupertinoColors.secondaryLabel
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (Platform.isIOS)
              Expanded(
                child: CupertinoButton.filled(
                  child: const Text('Manual Backup'),
                  onPressed: () async {
                    await widget.manager.createManualBackup(context);
                  },
                ),
              )
            else
              Expanded(
                child: ElevatedButton(
                  child: const Text('Manual Backup'),
                  onPressed: () async {
                    await widget.manager.createManualBackup(context);
                  },
                ),
              ),
            const SizedBox(width: 16),
            if (_isCloudAvailable)
              if (Platform.isIOS)
                Expanded(
                  child: CupertinoButton.filled(
                    child: const Text('Cloud Backup'),
                    onPressed: () async {
                      await widget.manager.createCloudBackup(context);
                      await _loadData(); // Refresh data after backup
                    },
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    child: const Text('Cloud Backup'),
                    onPressed: () async {
                      await widget.manager.createCloudBackup(context);
                      await _loadData(); // Refresh data after backup
                    },
                  ),
                )
            else
              if (Platform.isIOS)
                Expanded(
                  child: CupertinoButton.filled(
                    child: const Text('Sign in to iCloud'),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('iCloud Required'),
                          content: const Text('Please sign in to iCloud in your device settings to use cloud backup.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    child: const Text('Sign in to Google'),
                    onPressed: () async {
                      final success = await widget.manager.signInToCloudService();
                      if (success) {
                        await _loadData();
                      }
                    },
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildCloudBackupSection() {
    if (!_isCloudAvailable || _cloudBackups.isEmpty) return const SizedBox.shrink();

    final theme = Platform.isIOS ? CupertinoTheme.of(context) : Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cloud Backups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Platform.isIOS
                    ? CupertinoColors.label
                    : theme.textTheme.titleLarge?.color,
              ),
            ),
            if (Platform.isAndroid)
              TextButton(
                child: const Text('Sign out'),
                onPressed: () async {
                  await widget.manager.signOutFromCloudService();
                  await _loadData();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._cloudBackups.map((backup) {
          final name = _getBackupName(backup);
          final date = _getBackupDate(backup);

          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text(_formatDateTime(date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (Platform.isIOS)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.arrow_down_to_line),
                      onPressed: () async {
                        await widget.manager.restoreFromCloudBackup(context, backup);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        await widget.manager.restoreFromCloudBackup(context, backup);
                      },
                    ),
                  if (Platform.isIOS)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.delete),
                      onPressed: () async {
                        final confirm = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Delete Backup'),
                            content: const Text('Are you sure you want to delete this backup?'),
                            actions: [
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              CupertinoDialogAction(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await widget.manager.deleteCloudBackup(backup);
                          await _loadData();
                        }
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Backup'),
                            content: const Text('Are you sure you want to delete this backup?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await widget.manager.deleteCloudBackup(backup);
                          await _loadData();
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLocalBackupSection() {
    if (_localBackups.isEmpty) return const SizedBox.shrink();

    final theme = Platform.isIOS ? CupertinoTheme.of(context) : Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local Backups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Platform.isIOS
                ? CupertinoColors.label
                : theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        ..._localBackups.map((backup) {
          if (backup is! File) return const SizedBox.shrink();

          final name = backup.path.split('/').last;
          final date = backup.statSync().modified;

          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text(_formatDateTime(date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (Platform.isIOS)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.arrow_down_to_line),
                      onPressed: () async {
                        await widget.manager.restoreFromLocalBackup(context, backup);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        await widget.manager.restoreFromLocalBackup(context, backup);
                      },
                    ),
                  if (Platform.isIOS)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.delete),
                      onPressed: () async {
                        final confirm = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Delete Backup'),
                            content: const Text('Are you sure you want to delete this backup?'),
                            actions: [
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              CupertinoDialogAction(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await widget.manager.deleteLocalBackup(backup);
                          await _loadData();
                        }
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Backup'),
                            content: const Text('Are you sure you want to delete this backup?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await widget.manager.deleteLocalBackup(backup);
                          await _loadData();
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}