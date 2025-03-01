import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service that handles automatic backup schedules and settings
class AutoBackupService {
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _autoBackupIntervalKey = 'auto_backup_interval_days';
  static const String _lastAutoBackupKey = 'last_auto_backup_date';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if auto backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final enabled = await _secureStorage.read(key: _autoBackupEnabledKey);
    return enabled == 'true';
  }

  /// Set auto backup enabled status
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _autoBackupEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Get auto backup interval in days
  Future<int> getAutoBackupInterval() async {
    final interval = await _secureStorage.read(key: _autoBackupIntervalKey);
    return interval != null ? int.tryParse(interval) ?? 7 : 7; // Default: weekly
  }

  /// Set auto backup interval in days
  Future<void> setAutoBackupInterval(int days) async {
    await _secureStorage.write(
      key: _autoBackupIntervalKey,
      value: days.toString(),
    );
  }

  /// Get last auto backup date
  Future<DateTime?> getLastAutoBackupDate() async {
    final dateString = await _secureStorage.read(key: _lastAutoBackupKey);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Set last auto backup date
  Future<void> setLastAutoBackupDate(DateTime date) async {
    await _secureStorage.write(
      key: _lastAutoBackupKey,
      value: date.toIso8601String(),
    );
  }

  /// Check if auto backup is due
  Future<bool> isAutoBackupDue() async {
    final enabled = await isAutoBackupEnabled();
    if (!enabled) return false;

    final lastBackupDate = await getLastAutoBackupDate();
    if (lastBackupDate == null) return true; // No previous backup

    final interval = await getAutoBackupInterval();
    final now = DateTime.now();
    final nextBackupDate = lastBackupDate.add(Duration(days: interval));

    return now.isAfter(nextBackupDate);
  }
}

/// Settings screen for auto backup configuration
class BackupSettingsScreen extends StatefulWidget {
  final AutoBackupService autoBackupService;

  const BackupSettingsScreen({
    Key? key,
    required this.autoBackupService,
  }) : super(key: key);

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _isAutoBackupEnabled = false;
  int _backupInterval = 7;
  DateTime? _lastAutoBackup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    _isAutoBackupEnabled = await widget.autoBackupService.isAutoBackupEnabled();
    _backupInterval = await widget.autoBackupService.getAutoBackupInterval();
    _lastAutoBackup = await widget.autoBackupService.getLastAutoBackupDate();

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Automatic Backup'),
              subtitle: const Text('Periodically back up your data to cloud storage'),
              value: _isAutoBackupEnabled,
              onChanged: (value) async {
                await widget.autoBackupService.setAutoBackupEnabled(value);
                setState(() {
                  _isAutoBackupEnabled = value;
                });
              },
            ),

            if (_isAutoBackupEnabled) ...[
              const SizedBox(height: 16),
              const Text(
                'Backup Interval',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _backupInterval,
                items: [
                  DropdownMenuItem(value: 1, child: Text('Daily')),
                  DropdownMenuItem(value: 7, child: Text('Weekly')),
                  DropdownMenuItem(value: 30, child: Text('Monthly')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await widget.autoBackupService.setAutoBackupInterval(value);
                    setState(() {
                      _backupInterval = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
              Text(
                'Last automatic backup: ${_formatDateTime(_lastAutoBackup)}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}