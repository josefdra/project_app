import 'dart:async';

import 'package:project_hive_backend/api/project_api.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/sync/project_sync.dart';

/// {@template project_repository}
/// A repository that handles `project` related requests.
/// {@endtemplate}
class ProjectRepository {
  /// {@macro project_repository}
  ProjectRepository({
    required ProjectApi projectApi,
    required ProjectSyncService projectSyncService,
  })  : _projectApi = projectApi,
        _projectSyncService = projectSyncService;

  final ProjectApi _projectApi;
  final ProjectSyncService _projectSyncService;

  ProjectSyncService get syncService => _projectSyncService;

  /// Provides a [Stream] of active projects.
  Stream<List<Project>> get activeProjects => _projectApi.activeProjects;

  /// Provides a [Stream] of archived projects.
  Stream<List<Project>> get archivedProjects => _projectApi.archivedProjects;

  /// Adds a new [project]
  Future<void> addProject({required Project project}) =>
      _projectApi.addProject(project: project);

  /// Updates a [project]
  Future<void> updateProject(
          {required Project project, required bool active}) =>
      _projectApi.updateProject(project: project, active: active);

  Future<void> toggleArchiveStatus(
      {required Project project, required bool active}) {
    if (active) {
      return _projectApi.archiveProject(project: project);
    } else {
      return _projectApi.activateProject(project: project);
    }
  }

  // Trigger cloud synchronization
  Future<void> synchronize() async {
    _projectSyncService.sync();
  }

  /// Deletes the [project]
  Future<void> deleteProject(
          {required Project project, required bool active}) =>
      _projectApi.deleteProject(project: project, active: active);

  /// Disposes any resources managed by the repository
  void dispose() => _projectApi.close();
}
