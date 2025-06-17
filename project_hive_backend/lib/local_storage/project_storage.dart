import 'package:hive/hive.dart';
import 'package:project_hive_backend/api/project_api.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:rxdart/subjects.dart';

/// {@template project_local_storage}
/// A flutter implementation of the project ProjectLocalStorage
/// {@endtemplate}
class ProjectLocalStorage extends ProjectApi {
  /// {@macro project_local_storage}
  ProjectLocalStorage() {
    _refreshCache();
  }

  final Box<Project> _activeProjectsBox = Hive.box<Project>('projects');
  final Box<Project> _archivedProjectsBox =
      Hive.box<Project>('archived_projects');

  late final _activeProjectStreamController =
      BehaviorSubject<List<Project>>.seeded(
    const [],
  );

  late final _archivedProjectStreamController =
      BehaviorSubject<List<Project>>.seeded(
    const [],
  );

  late final Stream<List<Project>> _activeProjects =
      _activeProjectStreamController.stream;

  late final Stream<List<Project>> _archivedProjects =
      _archivedProjectStreamController.stream;

  Future<void> _refreshCache() async {
    final activeProjects = _activeProjectsBox.values.toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    final archiveProjects = _archivedProjectsBox.values.toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    _activeProjectStreamController.add(activeProjects);
    _archivedProjectStreamController.add(archiveProjects);
  }

  @override
  Stream<List<Project>> get activeProjects => _activeProjects;

  @override
  Stream<List<Project>> get archivedProjects => _archivedProjects;

  @override
  Future<void> addProject({required Project project}) async {
    final activeProjects = _activeProjectStreamController.value;
    activeProjects.add(project);

    _activeProjectStreamController.add(activeProjects);
    _activeProjectsBox.add(project);
  }

  @override
  Future<void> updateProject(
      {required Project project, required bool active}) async {
    final controller = active
        ? _activeProjectStreamController
        : _archivedProjectStreamController;
    final box = active ? _activeProjectsBox : _archivedProjectsBox;

    final projects = [...controller.value];
    final projectIndex = projects.indexWhere((p) => p.id == project.id);

    if (projectIndex < 0) {
      return;
    }

    projects[projectIndex] = project;
    await box.putAt(projectIndex, project);
    controller.add(projects);
  }

  @override
  Future<void> archiveProject({required Project project}) async {
    final activeProjects = [..._activeProjectStreamController.value];
    final archivedProjects = [..._archivedProjectStreamController.value];
    final projectIndex = activeProjects.indexWhere((p) => p.id == project.id);

    if (projectIndex < 0) {
      return;
    }

    activeProjects.removeAt(projectIndex);
    await _activeProjectsBox.deleteAt(projectIndex);
    archivedProjects.add(project);
    await _archivedProjectsBox.add(project);

    _activeProjectStreamController.add(activeProjects);
    _archivedProjectStreamController.add(archivedProjects);
  }

  @override
  Future<void> activateProject({required Project project}) async {
    final archivedProjects = [..._archivedProjectStreamController.value];
    final activeProjects = [..._activeProjectStreamController.value];
    final projectIndex = archivedProjects.indexWhere((p) => p.id == project.id);

    if (projectIndex < 0) {
      return;
    }

    archivedProjects.removeAt(projectIndex);
    await _archivedProjectsBox.deleteAt(projectIndex);
    activeProjects.add(project);
    await _activeProjectsBox.add(project);

    _archivedProjectStreamController.add(archivedProjects);
    _activeProjectStreamController.add(activeProjects);
  }

  @override
  Future<void> deleteProject(
      {required Project project, required bool active}) async {
    final controller = active
        ? _activeProjectStreamController
        : _archivedProjectStreamController;
    final box = active ? _activeProjectsBox : _archivedProjectsBox;

    final projects = [...controller.value];
    final projectIndex = projects.indexWhere((p) => p.id == project.id);

    if (projectIndex < 0) {
      return;
    }

    projects.removeAt(projectIndex);
    await box.deleteAt(projectIndex);
    controller.add(projects);
  }

  /// Close the [Stream]s
  @override
  Future<void> close() {
    _activeProjectStreamController.close();
    return _archivedProjectStreamController.close();
  }
}
