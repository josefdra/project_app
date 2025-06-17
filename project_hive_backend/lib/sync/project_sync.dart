import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:rxdart/subjects.dart';

// Enum for sync status types
enum SyncStatus { initial, syncing, synced }

/// {@template project_sync_service}
/// A dart implementation of a synchronization service
/// {@endtemplate}
class ProjectSyncService {
  /// {@macro project_sync_service}
  ProjectSyncService() {
    _init();
  }

  /// StreamController to broadcast updates
  final _syncStatusController =
      BehaviorSubject<SyncStatus>.seeded(SyncStatus.initial);

  /// Stream of status updates
  Stream<SyncStatus> get syncUpdates => _syncStatusController.stream;

  final _projectsBoxName = 'projects';
  final _archivedProjectsBoxName = 'archived_projects';
  final _methodChannel = MethodChannel('com.draexl.project_manager/icloud');
  late final String? _iCloudDocumentsPath;

  /// Initialize the sync service
  Future<void> _init() async {
    _iCloudDocumentsPath =
        await _methodChannel.invokeMethod<String>('getICloudDocumentsPath');

    await _createDirs();
    await sync();
  }

  Future<void> _createDirs() async {
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
  Future<void> sync() async {
    if (_iCloudDocumentsPath == null ||
        await syncUpdates.first == SyncStatus.syncing) {
      return;
    }

    _syncStatusController.add(SyncStatus.syncing);

    await _uploadLocalDataToCloud();
    await _downloadCloudDataToLocal();

    _syncStatusController.add(SyncStatus.synced);
  }

  // Upload local Hive data to iCloud
  Future<void> _uploadLocalDataToCloud() async {
    final Box<Project> projectsBox = Hive.box<Project>(_projectsBoxName);
    final Box<Project> archivedProjectsBox =
        Hive.box<Project>(_archivedProjectsBoxName);

    await _uploadProjects(
      projects: projectsBox.values.toList(),
      directory: '$_iCloudDocumentsPath/projects',
    );

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
      final Map<String, dynamic> projectMap = {
        'id': project.id,
        'name': project.name,
        'date': project.date.toIso8601String(),
        'lastEdited': project.lastEdited.toIso8601String(),
        'description': project.description,
        'items': project.items
            .map((item) => {
                  'quantity': item.quantity,
                  'unit': item.unit,
                  'description': item.description,
                  'pricePerUnit': item.pricePerUnit,
                })
            .toList(),
        'images': project.images,
      };

      final file = File('$directory/${project.id}.json');
      await file.writeAsString(jsonEncode(projectMap));
    }
  }

  // Download cloud data to local Hive
  Future<void> _downloadCloudDataToLocal() async {
    final Box<Project> projectsBox = Hive.box<Project>(_projectsBoxName);
    final Box<Project> archivedProjectsBox =
        Hive.box<Project>(_archivedProjectsBoxName);

    final activeProjects =
        await _loadProjectsFromDirectory('$_iCloudDocumentsPath/projects');
    final archivedProjects = await _loadProjectsFromDirectory(
        '$_iCloudDocumentsPath/archived_projects');

    await _mergeProjects(activeProjects, projectsBox);
    await _mergeProjects(archivedProjects, archivedProjectsBox);
  }

  // Load projects from a directory
  Future<List<Project>> _loadProjectsFromDirectory(String directory) async {
    final projects = <Project>[];
    final dir = Directory(directory);

    await for (final fileEntity in dir.list()) {
      if (fileEntity is File && fileEntity.path.endsWith('.json')) {
        final content = await fileEntity.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final project = Project(
          id: data['id'],
          name: data['name'],
          date: DateTime.parse(data['date']),
          lastEdited: DateTime.parse(data['lastEdited']),
          description: data['description'],
          items: (data['items'] as List)
              .map((item) => ProjectItem(
                    quantity: item['quantity'],
                    unit: item['unit'],
                    description: item['description'],
                    pricePerUnit: item['pricePerUnit'],
                  ))
              .toList(),
          images: List<String>.from(data['images']),
        );

        projects.add(project);
      }
    }

    return projects;
  }

  // Merge cloud projects with local box
  Future<void> _mergeProjects(List<Project> cloudProjects, Box<Project> localBox) async {
    final localProjectsMap = <String, Project>{};

    for (final project in localBox.values) {
      localProjectsMap[project.id] = project;
    }

    for (final cloudProject in cloudProjects) {
      final localProject = localProjectsMap[cloudProject.id];

      if (localProject == null) {
        await localBox.add(cloudProject);
      } else {
        if (cloudProject.lastEdited.isAfter(localProject.lastEdited)) {
          await localBox.put(localProject.key, cloudProject);
        }
      }
    }
  }

  /// Dispose
  void dispose() {
    _syncStatusController.close();
  }
}
