import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GoogleDriveBackupService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _lastGDriveBackupKey = 'last_gdrive_backup';
  static const String _appFolderName = 'ProjektApp_Backups';
  String? _appFolderId;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // Sign in to Google Drive
  Future<bool> signIn() async {
    try {
      if (!Platform.isAndroid) return false;

      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      debugPrint('Error signing in to Google: $e');
      return false;
    }
  }

  // Sign out from Google Drive
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  // Check if signed in
  Future<bool> isSignedIn() async {
    try {
      if (!Platform.isAndroid) return false;
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      debugPrint('Error checking sign in status: $e');
      return false;
    }
  }

  // Get Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return null;
      }

      final authHeaders = await account.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error getting Drive API: $e');
      return null;
    }
  }

  // Get or create app folder
  Future<String?> _getAppFolder() async {
    if (_appFolderId != null) return _appFolderId;

    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      // Check if the folder already exists
      final fileList = await driveApi.files.list(
        q: "name='$_appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _appFolderId = fileList.files![0].id;
        return _appFolderId;
      }

      // Create the folder
      final folder = drive.File(
        name: _appFolderName,
        mimeType: 'application/vnd.google-apps.folder',
      );

      final result = await driveApi.files.create(folder);
      _appFolderId = result.id;
      return _appFolderId;
    } catch (e) {
      debugPrint('Error creating app folder: $e');
      return null;
    }
  }

  // Upload backup to Google Drive
  Future<bool> uploadBackupToGoogleDrive(File backupFile) async {
    try {
      if (!Platform.isAndroid) return false;
      if (!await isSignedIn()) {
        final signInResult = await signIn();
        if (!signInResult) return false;
      }

      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getAppFolder();
      if (folderId == null) return false;

      // Prepare the file metadata
      final fileName = path.basename(backupFile.path);

      // Check if file with this name already exists
      final existingFiles = await driveApi.files.list(
        q: "name='$fileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        fields: 'files(id,name)',
      );

      // Delete existing file with same name if exists
      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        for (final file in existingFiles.files!) {
          await driveApi.files.delete(file.id!);
        }
      }

      // Create file metadata
      final driveFile = drive.File(
        name: fileName,
        parents: [folderId],
      );

      // Upload file content
      final media = drive.Media(
        backupFile.openRead(),
        backupFile.lengthSync(),
      );

      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      // Update last backup date
      await _secureStorage.write(
        key: _lastGDriveBackupKey,
        value: DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      return false;
    }
  }

  // Get last Google Drive backup date
  Future<DateTime?> getLastGoogleDriveBackupDate() async {
    final dateString = await _secureStorage.read(key: _lastGDriveBackupKey);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // List backups available in Google Drive
  Future<List<drive.File>> listGoogleDriveBackups() async {
    try {
      if (!Platform.isAndroid) return [];
      if (!await isSignedIn()) return [];

      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];

      final folderId = await _getAppFolder();
      if (folderId == null) return [];

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed=false",
        spaces: 'drive',
        fields: 'files(id, name, modifiedTime, size)',
        orderBy: 'modifiedTime desc',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing Google Drive backups: $e');
      return [];
    }
  }

  // Download backup from Google Drive
  Future<File?> downloadBackupFromGoogleDrive(drive.File driveFile) async {
    try {
      if (!Platform.isAndroid) return null;
      if (!await isSignedIn()) return null;

      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // Get temporary directory
      final tempDir = await Directory.systemTemp.createTemp('backup_');
      final localFile = File('${tempDir.path}/${driveFile.name}');

      // Download the file
      final response = await driveApi.files.get(
        driveFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as http.Response;

      await localFile.writeAsBytes(response.bodyBytes);
      return localFile;
    } catch (e) {
      debugPrint('Error downloading from Google Drive: $e');
      return null;
    }
  }

  // Delete a backup from Google Drive
  Future<bool> deleteGoogleDriveBackup(drive.File driveFile) async {
    try {
      if (!Platform.isAndroid) return false;
      if (!await isSignedIn()) return false;

      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      await driveApi.files.delete(driveFile.id!);
      return true;
    } catch (e) {
      debugPrint('Error deleting Google Drive backup: $e');
      return false;
    }
  }
}

// HTTP Client for Google APIs
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}