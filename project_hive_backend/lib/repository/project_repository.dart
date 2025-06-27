import 'dart:async';

import 'package:project_hive_backend/api/project_api.dart';
import 'package:project_hive_backend/api/project_models/project.dart';

/// {@template project_repository}
/// A repository that handles `project` related requests.
/// {@endtemplate}
class ProjectRepository {
  /// {@macro project_repository}
  ProjectRepository({required ProjectApi projectApi})
      : _projectApi = projectApi;

  final ProjectApi _projectApi;

  /// Provides a [Stream] of active projects.
  Stream<List<Project>> get activeProjects => _projectApi.activeProjects;

  /// Provides a [Stream] of archived projects.
  Stream<List<Project>> get archivedProjects => _projectApi.archivedProjects;

  /// Adds a new [project]
  Future<void> addProject({required Project project}) async {
    await _projectApi.addProject(project: project);
  }

  /// Updates a [project]
  Future<void> updateProject(
      {required Project project, required bool active}) async {
    await _projectApi.updateProject(project: project, active: active);
  }

  Future<void> toggleArchiveStatus(
      {required Project project, required bool active}) async {
    if (active) {
      await _projectApi.archiveProject(project: project);
    } else {
      await _projectApi.activateProject(project: project);
    }
  }

  /// Deletes the [project]
  Future<void> deleteProject(
      {required Project project, required bool active}) async {
    await _projectApi.deleteProject(project: project, active: active);
  }

  /// Disposes any resources managed by the repository
  void dispose() => _projectApi.close();
}
