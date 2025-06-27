import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_hive_backend/api/project_api.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template project_local_storage}
/// A flutter implementation of the project ProjectLocalStorage
/// {@endtemplate}
class ProjectLocalStorage extends ProjectApi {
  /// {@macro project_local_storage}
  ProjectLocalStorage() {
    _init();
  }

  late final BoxCollection boxCollection;
  late final CollectionBox<Project> _activeProjectsBox;
  late final CollectionBox<Project> _archivedProjectsBox;
  final versionKey = "__version_key__";
  final _methodChannel = MethodChannel('com.draexl.project-manager/iCloud');

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

  Future<String?> _getPath() async {
    try {
      final path =
          await _methodChannel.invokeMethod<String>('getICloudDocumentsPath');
      debugPrint('iCloud Documents path: $path');
      return path;
    } on PlatformException catch (e) {
      debugPrint('Failed to get iCloud Documents path: ${e.message}');
      return null;
    }
  }

  Future<void> _migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(versionKey);

    if(version == null || version == 0){
      final projectBox = await Hive.openBox<Project>('projects');
      final projectMap = projectBox.toMap();

      for (final key in projectMap.keys){
        _activeProjectsBox.put(key, projectMap[key]!);
      }

      projectBox.deleteFromDisk();

      final archivedProjectBox = await Hive.openBox<Project>('archived_projects');
      final archivedProjectMap = archivedProjectBox.toMap();
      
      for (final key in archivedProjectMap.keys){
        _archivedProjectsBox.put(key, archivedProjectMap[key]!);
      }

      archivedProjectBox.deleteFromDisk();
      
      prefs.setInt(versionKey, 1);
    }
  }

  Future<void> _init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(ProjectItemAdapter());

    final iCloudPath = await _getPath();
    boxCollection = await BoxCollection.open(
        'ProjectHive', {'projects', 'archivedProjects'},
        path: iCloudPath);
    _activeProjectsBox = await boxCollection.openBox<Project>('projects');
    _archivedProjectsBox =
        await boxCollection.openBox<Project>('archivedProjects');

    _migrate();

    final activeProjects = await _activeProjectsBox.getAllValues();
    final activeProjectsList = [...activeProjects.values]
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    final archivedProjects = await _archivedProjectsBox.getAllValues();
    final archivedProjectsList = [...archivedProjects.values]
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    _activeProjectStreamController.add(activeProjectsList);
    _archivedProjectStreamController.add(archivedProjectsList);
  }

  @override
  Stream<List<Project>> get activeProjects => _activeProjects;

  @override
  Stream<List<Project>> get archivedProjects => _archivedProjects;

  @override
  Future<void> addProject({required Project project}) async {
    final updatedProjects = [..._activeProjectStreamController.value];
    updatedProjects.add(project);
    updatedProjects.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    _activeProjectStreamController.add(updatedProjects);
    _activeProjectsBox.put(project.id, project);
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
    await box.put(project.id, project);
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
    await _activeProjectsBox.delete(project.id);

    final newProject = project.copyWith();

    archivedProjects.add(newProject);
    await _archivedProjectsBox.put(newProject.id, newProject);

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
    await _archivedProjectsBox.delete(project.id);

    final newProject = project.copyWith();

    activeProjects.add(newProject);
    await _activeProjectsBox.put(newProject.id, newProject);

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
    await box.delete(project.id);
    controller.add(projects);
  }

  /// Close the [Stream]s
  @override
  Future<void> close() {
    _activeProjectStreamController.close();
    return _archivedProjectStreamController.close();
  }
}
