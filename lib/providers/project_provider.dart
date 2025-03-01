import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';

class ProjectProvider extends ChangeNotifier {
  final Box<Project> _projectsBox = Hive.box<Project>('projects');
  final Box<Project> _archivedProjectsBox = Hive.box<Project>('archived_projects');

  List<Project> get projects => _projectsBox.values.toList()
    ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

  List<Project> get archivedProjects => _archivedProjectsBox.values.toList()
    ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

  Project getProjectById(String id) {
    return _projectsBox.values.firstWhere(
          (project) => project.id == id,
      orElse: () => _archivedProjectsBox.values.firstWhere(
            (project) => project.id == id,
        orElse: () => throw Exception('Project not found'),
      ),
    );
  }

  Future<void> addProject(Project project) async {
    await _projectsBox.add(project);
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    final index = _projectsBox.values.toList().indexWhere((p) => p.id == project.id);
    if (index != -1) {
      await _projectsBox.putAt(index, project);
      notifyListeners();
    }
  }

  Future<void> deleteProjects(List<String> projectIds) async {
    await _projectsBox.deleteAll(
        _projectsBox.values.where((p) => projectIds.contains(p.id)).map((p) => p.key)
    );
    await _archivedProjectsBox.deleteAll(
        _archivedProjectsBox.values.where((p) => projectIds.contains(p.id)).map((p) => p.key)
    );
    notifyListeners();
  }

  Future<void> toggleArchiveStatus(String projectId) async {
    final activeProject = _projectsBox.values.firstWhere(
          (p) => p.id == projectId,
      orElse: () => _archivedProjectsBox.values.firstWhere(
            (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      ),
    );

    if (_projectsBox.values.contains(activeProject)) {
      await _projectsBox.delete(activeProject.key);
      await _archivedProjectsBox.add(activeProject);
    } else {
      await _archivedProjectsBox.delete(activeProject.key);
      await _projectsBox.add(activeProject);
    }

    notifyListeners();
  }

  List<Project> searchProjects(String query, {bool archived = false}) {
    final searchList = archived ? archivedProjects : projects;
    if (query.isEmpty) return searchList;

    return searchList.where((project) =>
        project.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}