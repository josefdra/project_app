import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class ICloudBackupService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _lastICloudBackupKey = 'last_icloud_backup';
  static const String _backupFolder = 'ProjektApp_Backups';

  // Check if iCloud is available
  Future<bool> isICloudAvailable() async {
    try {
      if (!Platform.isIOS) return false;

      final containers = await ICloudStorage.getICloudContainers();
      return containers.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking iCloud availability: $e');
      return false;
    }
  }

  // Upload backup file to iCloud
  Future<bool> uploadBackupToICloud(File backupFile) async {
    try {
      if (!Platform.isIOS) return false;

      // Check if iCloud is available
      if (!await isICloudAvailable()) {
        return false;
      }

      // Get filename without path
      final filename = backupFile.path.split('/').last;

      // Upload file
      await ICloudStorage.upload(
        containerId: ICloudContainers.documents,
        path: _backupFolder,
        filename: filename,
        destinationFilename: filename,
        file: backupFile,
      );

      // Update last backup date
      await _secureStorage.write(
          key: _lastICloudBackupKey,
          value: DateTime.now().toIso8601String()
      );

      return true;
    } catch (e) {
      debugPrint('Error uploading to iCloud: $e');
      return false;
    }
  }

  // Get last iCloud backup date
  Future<DateTime?> getLastICloudBackupDate() async {
    final dateString = await _secureStorage.read(key: _lastICloudBackupKey);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // List backups available in iCloud
  Future<List<ICloudFile>> listICloudBackups() async {
    try {
      if (!Platform.isIOS) return [];
      if (!await isICloudAvailable()) return [];

      final files = await ICloudStorage.list(
        containerId: ICloudContainers.documents,
        path: _backupFolder,
      );

      // Sort files by date, newest first
      files.sort((a, b) => b.date.compareTo(a.date));

      return files;
    } catch (e) {
      debugPrint('Error listing iCloud backups: $e');
      return [];
    }
  }

  // Download backup from iCloud
  Future<File?> downloadBackupFromICloud(ICloudFile iCloudFile) async {
    try {
      if (!Platform.isIOS) return null;

      // Get temporary directory to store the downloaded file
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/${iCloudFile.filename}');

      // Download the file
      await ICloudStorage.download(
        containerId: ICloudContainers.documents,
        path: _backupFolder,
        filename: iCloudFile.filename,
        destinationFilePath: localFile.path,
      );

      return localFile;
    } catch (e) {
      debugPrint('Error downloading from iCloud: $e');
      return null;
    }
  }

  // Delete a backup from iCloud
  Future<bool> deleteICloudBackup(ICloudFile iCloudFile) async {
    try {
      if (!Platform.isIOS) return false;

      await ICloudStorage.delete(
        containerId: ICloudContainers.documents,
        path: _backupFolder,
        filename: iCloudFile.filename,
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting iCloud backup: $e');
      return false;
    }
  }
}