import 'dart:async';

import 'package:project_hive_backend/api/project_api.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/sync/project_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template project_repository}
/// A repository that handles `project` related requests.
/// {@endtemplate}
class ProjectRepository {
  /// {@macro project_repository}
  ProjectRepository({
    required ProjectApi projectApi,
    required ProjectSyncService projectSyncService,
  })  : _projectApi = projectApi,
        _projectSyncService = projectSyncService {
    _init();
  }

  final ProjectApi _projectApi;
  final ProjectSyncService _projectSyncService;

  static const _versionKey = '__version_key__';
  static SharedPreferences? _sharedPrefs;

  ProjectSyncService get syncService => _projectSyncService;

  /// Provides a [Stream] of active projects.
  Stream<List<Project>> get activeProjects => _projectApi.activeProjects;

  /// Provides a [Stream] of archived projects.
  Stream<List<Project>> get archivedProjects => _projectApi.archivedProjects;

  Future<void> _executeVersionFunction({required int version}) async {
    // if (version == 0) {
    //   await _projectSyncService.uploadAllToCloud();
    //   await _sharedPrefs!.setInt(_versionKey, version + 1);
    // }
  }

  Future<void> _init() async {
    _sharedPrefs = await SharedPreferences.getInstance();
    final version = _sharedPrefs!.getInt(_versionKey);
    _executeVersionFunction(version: version ?? 0);
  }

  /// Adds a new [project]
  Future<void> addProject({required Project project}) async {
    await _projectApi.addProject(project: project);
    await _projectSyncService.sync();
  }

  /// Updates a [project]
  Future<void> updateProject(
      {required Project project, required bool active}) async {
    await _projectApi.updateProject(project: project, active: active);
    await _projectSyncService.sync();
  }

  Future<void> toggleArchiveStatus(
      {required Project project, required bool active}) async {
    if (active) {
      await _projectApi.archiveProject(project: project);
    } else {
      await _projectApi.activateProject(project: project);
    }

    await _projectSyncService.sync();
  }

  /// Trigger cloud synchronization
  Future<void> synchronize() => _projectSyncService.sync();

  /// Deletes the [project]
  Future<void> deleteProject(
      {required Project project, required bool active}) async {
    await _projectApi.deleteProject(project: project, active: active);
    await _projectSyncService.sync();
  }

  /// Disposes any resources managed by the repository
  void dispose() => _projectApi.close();
}
