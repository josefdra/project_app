import 'package:project_hive_backend/api/project_models/project.dart';

/// {@template project_api}
/// The interface for an API that provides access to projects.
/// {@endtemplate}
abstract class ProjectApi {
  /// {@macro project_api}
  const ProjectApi();

  /// Provides a stream of active projects
  Stream<List<Project>> get activeProjects;

  /// Provides a stream of archived projects
  Stream<List<Project>> get archivedProjects;

  /// Adds a new [project]
  Future<void> addProject({required Project project});

  /// Updates a [project]
  Future<void> updateProject({required Project project, required bool active});

  /// Archives the [project]
  Future<void> archiveProject({required Project project});

  /// Activates the [project]
  Future<void> activateProject({required Project project});

  /// Deletes the [project]
  Future<void> deleteProject({required Project project, required bool active});

  /// Closes the [Stream]s
  Future<void> close();
}
