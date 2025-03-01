import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:projekt_app/models/project.dart';

class BackupService {
  static const String _lastBackupDateKey = 'last_backup_date';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get the backup directory
  Future<Directory> get _backupDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // Create a backup file with timestamp
  Future<File> createBackupFile() async {
    try {
      // Get projects and archived projects boxes
      final projectsBox = Hive.box<Project>('projects');
      final archivedProjectsBox = Hive.box<Project>('archived_projects');

      // Create a backup data structure
      final backupData = {
        'version': 1,  // For future compatibility
        'timestamp': DateTime.now().toIso8601String(),
        'projects': projectsBox.values.map((project) => _projectToJson(project)).toList(),
        'archivedProjects': archivedProjectsBox.values.map((project) => _projectToJson(project)).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Create backup file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = await _backupDir;
      final backupFile = File('${backupDir.path}/backup_$timestamp.json');

      // Write to file
      await backupFile.writeAsString(jsonString);

      // Update last backup date
      await _secureStorage.write(
          key: _lastBackupDateKey,
          value: DateTime.now().toIso8601String()
      );

      return backupFile;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  // Convert a Project to JSON Map (handling circular references)
  Map<String, dynamic> _projectToJson(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'date': project.date.toIso8601String(),
      'lastEdited': project.lastEdited.toIso8601String(),
      'items': project.items.map((item) => {
        'quantity': item.quantity,
        'unit': item.unit,
        'description': item.description,
        'pricePerUnit': item.pricePerUnit,
      }).toList(),
      'images': project.images,
    };
  }

  // Get last backup date
  Future<DateTime?> getLastBackupDate() async {
    final dateString = await _secureStorage.read(key: _lastBackupDateKey);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Share backup file (for manual backup)
  Future<void> shareBackup() async {
    final backupFile = await createBackupFile();
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      subject: 'Projekt App Backup',
    );
  }

  // Restore from backup file
  Future<bool> restoreFromFile(File backupFile) async {
    try {
      // Read backup file
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData['version'] as int;
      if (version > 1) {
        // Handle future version compatibility
        debugPrint('Warning: Backup version $version is newer than app version');
      }

      // Get boxes
      final projectsBox = Hive.box<Project>('projects');
      final archivedProjectsBox = Hive.box<Project>('archived_projects');

      // Clear current data
      await projectsBox.clear();
      await archivedProjectsBox.clear();

      // Restore projects
      final projects = (backupData['projects'] as List).map((projectJson) {
        return _jsonToProject(projectJson as Map<String, dynamic>);
      }).toList();

      final archivedProjects = (backupData['archivedProjects'] as List).map((projectJson) {
        return _jsonToProject(projectJson as Map<String, dynamic>);
      }).toList();

      // Add projects to boxes
      await projectsBox.addAll(projects);
      await archivedProjectsBox.addAll(archivedProjects);

      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }

  // Convert JSON Map to Project
  Project _jsonToProject(Map<String, dynamic> json) {
    final items = (json['items'] as List).map((itemJson) {
      return ProjectItem(
        quantity: itemJson['quantity'] as double,
        unit: itemJson['unit'] as String,
        description: itemJson['description'] as String,
        pricePerUnit: itemJson['pricePerUnit'] as double,
      );
    }).toList();

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      lastEdited: DateTime.parse(json['lastEdited'] as String),
      items: items,
      images: (json['images'] as List).cast<String>(),
    );
  }

  // List available backups
  Future<List<FileSystemEntity>> listBackups() async {
    final backupDir = await _backupDir;
    final files = await backupDir.list().toList();
    // Sort by file modification date, newest first
    files.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });
    return files;
  }

  // Delete a backup file
  Future<void> deleteBackup(File backupFile) async {
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
  }
}