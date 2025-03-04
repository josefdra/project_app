import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class CloudSyncService {
  static const String _kProjectsBoxName = 'projects';
  static const String _kArchivedProjectsBoxName = 'archived_projects';
  static const _methodChannel = MethodChannel('com.draexl.project_manager/icloud');

  // Singleton pattern
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  // Stream controllers for sync events
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Flag to track initial sync
  bool _initialSyncComplete = false;
  bool get initialSyncComplete => _initialSyncComplete;

  // Sync properties
  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isSyncing = false;
  String? _iCloudDocumentsPath;

  // Initialize the sync service
  Future<void> initialize() async {
    try {
      // Get the iCloud Documents path
      _iCloudDocumentsPath = await _getICloudDocumentsPath();

      // Create directories if they don't exist
      if (_iCloudDocumentsPath != null) {
        await _createDirectoriesIfNeeded();

        // Perform initial sync
        await synchronize();
        _initialSyncComplete = true;
      } else {
        _syncStatusController.add(SyncStatus(
          status: SyncStatusType.error,
          message: 'iCloud not available',
        ));
      }
    } catch (e) {
      debugPrint('Error initializing CloudSyncService: $e');
      _syncStatusController.add(SyncStatus(
        status: SyncStatusType.error,
        message: 'Error initializing sync: $e',
      ));
    }
  }

  // Get the iCloud Documents path using native code
  Future<String?> _getICloudDocumentsPath() async {
    try {
      final path = await _methodChannel.invokeMethod<String>('getICloudDocumentsPath');
      debugPrint('iCloud Documents path: $path');
      return path;
    } on PlatformException catch (e) {
      debugPrint('Failed to get iCloud Documents path: ${e.message}');
      return null;
    }
  }

  // Create necessary directories for sync
  Future<void> _createDirectoriesIfNeeded() async {
    if (_iCloudDocumentsPath == null) return;

    final projectsDir = Directory('$_iCloudDocumentsPath/projects');
    final archivedDir = Directory('$_iCloudDocumentsPath/archived_projects');

    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }

    if (!await archivedDir.exists()) {
      await archivedDir.create(recursive: true);
    }
  }

  // Synchronize data between local and cloud storage
  Future<void> synchronize() async {
    if (_isSyncing || _iCloudDocumentsPath == null) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(
      status: SyncStatusType.syncing,
      message: 'Synchronisierung...',
    ));

    try {
      // Upload local data to iCloud
      await _uploadLocalDataToCloud();

      // Download cloud data to local
      await _downloadCloudDataToLocal();

      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus(
        status: SyncStatusType.synced,
        message: 'Erfolgreich synchronisiert',
        timestamp: _lastSyncTime,
      ));
    } catch (e) {
      debugPrint('Error during synchronization: $e');
      _syncStatusController.add(SyncStatus(
        status: SyncStatusType.error,
        message: 'Synchronisierungsfehler: $e',
      ));
    } finally {
      _isSyncing = false;
    }
  }

  // Upload local Hive data to iCloud
  Future<void> _uploadLocalDataToCloud() async {
    if (_iCloudDocumentsPath == null) return;

    // Get local projects
    final Box<Project> projectsBox = Hive.box<Project>(_kProjectsBoxName);
    final Box<Project> archivedProjectsBox = Hive.box<Project>(_kArchivedProjectsBoxName);

    // Upload active projects
    await _uploadProjects(
      projects: projectsBox.values.toList(),
      directory: '$_iCloudDocumentsPath/projects',
    );

    // Upload archived projects
    await _uploadProjects(
      projects: archivedProjectsBox.values.toList(),
      directory: '$_iCloudDocumentsPath/archived_projects',
    );
  }

  // Upload a list of projects to the specified directory
  Future<void> _uploadProjects({
    required List<Project> projects,
    required String directory,
  }) async {
    for (final project in projects) {
      // Convert project to JSON
      final Map<String, dynamic> projectMap = {
        'id': project.id,
        'name': project.name,
        'date': project.date.toIso8601String(),
        'lastEdited': project.lastEdited.toIso8601String(),
        'description': project.description,
        'items': project.items.map((item) => {
          'quantity': item.quantity,
          'unit': item.unit,
          'description': item.description,
          'pricePerUnit': item.pricePerUnit,
        }).toList(),
        'images': project.images,
      };

      // Create or update the project file
      final file = File('$directory/${project.id}.json');
      await file.writeAsString(jsonEncode(projectMap));
    }
  }

  // Download cloud data to local Hive
  Future<void> _downloadCloudDataToLocal() async {
    if (_iCloudDocumentsPath == null) return;

    final Box<Project> projectsBox = Hive.box<Project>(_kProjectsBoxName);
    final Box<Project> archivedProjectsBox = Hive.box<Project>(_kArchivedProjectsBoxName);

    // Get cloud projects
    final activeProjects = await _loadProjectsFromDirectory('$_iCloudDocumentsPath/projects');
    final archivedProjects = await _loadProjectsFromDirectory('$_iCloudDocumentsPath/archived_projects');

    // Merge with local data
    await _mergeProjects(activeProjects, projectsBox);
    await _mergeProjects(archivedProjects, archivedProjectsBox);
  }

  // Load projects from a directory
  Future<List<Project>> _loadProjectsFromDirectory(String directory) async {
    final projects = <Project>[];
    final dir = Directory(directory);

    if (!await dir.exists()) return projects;

    await for (final fileEntity in dir.list()) {
      if (fileEntity is File && fileEntity.path.endsWith('.json')) {
        try {
          final content = await fileEntity.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;

          final project = Project(
            id: data['id'],
            name: data['name'],
            date: DateTime.parse(data['date']),
            lastEdited: DateTime.parse(data['lastEdited']),
            description: data['description'],
            items: (data['items'] as List).map((item) => ProjectItem(
              quantity: item['quantity'],
              unit: item['unit'],
              description: item['description'],
              pricePerUnit: item['pricePerUnit'],
            )).toList(),
            images: List<String>.from(data['images']),
          );

          projects.add(project);
        } catch (e) {
          debugPrint('Error loading project from file ${fileEntity.path}: $e');
        }
      }
    }

    return projects;
  }

  // Merge cloud projects with local box
  Future<void> _mergeProjects(List<Project> cloudProjects, Box<Project> localBox) async {
    final localProjectsMap = <String, Project>{};

    // Create a map of local projects by ID
    for (final project in localBox.values) {
      localProjectsMap[project.id] = project;
    }

    // Process each cloud project
    for (final cloudProject in cloudProjects) {
      final localProject = localProjectsMap[cloudProject.id];

      if (localProject == null) {
        // New project from cloud - add to local
        await localBox.add(cloudProject);
      } else {
        // Existing project - use the most recently edited version
        if (cloudProject.lastEdited.isAfter(localProject.lastEdited)) {
          // Update local with cloud data
          await localBox.put(localProject.key, cloudProject);
        }
      }
    }
  }

  // Clean up resources
  void dispose() {
    _syncStatusController.close();
  }
}

// Enum for sync status types
enum SyncStatusType {
  syncing,
  synced,
  error,
}

// Class to represent sync status
class SyncStatus {
  final SyncStatusType status;
  final String message;
  final DateTime? timestamp;

  SyncStatus({
    required this.status,
    required this.message,
    this.timestamp,
  });
}