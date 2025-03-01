import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';

class ProjectProvider extends ChangeNotifier {
  final Box<Project> _projectsBox = Hive.box<Project>('projects');
  final Box<Project> _archivedProjectsBox = Hive.box<Project>('archived_projects');
  String _searchQuery = '';

  // Cache the projects to avoid rebuilding during navigation
  List<Project>? _cachedProjects;
  List<Project>? _cachedArchivedProjects;

  // Getter for projects with lazy loading pattern
  List<Project> get projects {
    if (_cachedProjects == null) {
      _refreshCache();
    }

    final allProjects = _cachedProjects!;

    if (_searchQuery.isEmpty) return allProjects;

    return allProjects.where((project) =>
        project.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Getter for archived projects with lazy loading pattern
  List<Project> get archivedProjects {
    if (_cachedArchivedProjects == null) {
      _refreshCache();
    }

    final allArchived = _cachedArchivedProjects!;

    if (_searchQuery.isEmpty) return allArchived;

    return allArchived.where((project) =>
        project.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Refresh the cached lists - called when needed
  void _refreshCache() {
    final activeProjects = _projectsBox.values.toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    final archiveProjects = _archivedProjectsBox.values.toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    _cachedProjects = activeProjects;
    _cachedArchivedProjects = archiveProjects;
  }

  // Explicitly refresh data when needed
  void refreshData() {
    _refreshCache();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Project getProjectById(String id) {
    try {
      // Check active projects first
      for (final project in projects) {
        if (project.id == id) return project;
      }

      // Then check archived projects
      for (final project in archivedProjects) {
        if (project.id == id) return project;
      }

      throw Exception('Project not found: $id');
    } catch (e) {
      throw Exception('Project not found: $id');
    }
  }

  Future<void> addProject(Project project) async {
    await _projectsBox.add(project);
    _cachedProjects = null; // Invalidate cache
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    project.updateLastEdited();

    try {
      // Find the project in the active projects box
      final activeProjects = _projectsBox.values.toList();
      final activeIndex = activeProjects.indexWhere((p) => p.id == project.id);

      if (activeIndex != -1) {
        await _projectsBox.putAt(activeIndex, project);
        _cachedProjects = null; // Invalidate cache
        notifyListeners();
        return;
      }

      // If not found in active projects, check archived projects
      final archivedProjects = _archivedProjectsBox.values.toList();
      final archivedIndex = archivedProjects.indexWhere((p) => p.id == project.id);

      if (archivedIndex != -1) {
        await _archivedProjectsBox.putAt(archivedIndex, project);
        _cachedArchivedProjects = null; // Invalidate cache
        notifyListeners();
        return;
      }

      throw Exception('Project not found for update: ${project.id}');
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      // Check active projects
      final activeProjects = _projectsBox.values.toList();
      final activeProjectIndex = activeProjects.indexWhere((p) => p.id == projectId);

      if (activeProjectIndex != -1) {
        final activeProject = activeProjects[activeProjectIndex];
        await _projectsBox.delete(activeProject.key);
        _cachedProjects = null; // Invalidate cache
        notifyListeners();
        return;
      }

      // Check archived projects
      final archivedProjects = _archivedProjectsBox.values.toList();
      final archivedProjectIndex = archivedProjects.indexWhere((p) => p.id == projectId);

      if (archivedProjectIndex != -1) {
        final archivedProject = archivedProjects[archivedProjectIndex];
        await _archivedProjectsBox.delete(archivedProject.key);
        _cachedArchivedProjects = null; // Invalidate cache
        notifyListeners();
        return;
      }

      throw Exception('Project not found for deletion: $projectId');
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }

  Future<void> toggleArchiveStatus(String projectId) async {
    try {
      // First, check active projects
      final activeProjects = _projectsBox.values.toList();
      final activeProjectIndex = activeProjects.indexWhere((p) => p.id == projectId);

      if (activeProjectIndex != -1) {
        // Move from active to archived
        final activeProject = activeProjects[activeProjectIndex];
        await _projectsBox.delete(activeProject.key);
        activeProject.updateLastEdited();
        await _archivedProjectsBox.add(activeProject);

        // Invalidate both caches
        _cachedProjects = null;
        _cachedArchivedProjects = null;

        notifyListeners();
        return;
      }

      // Then check archived projects
      final archivedProjects = _archivedProjectsBox.values.toList();
      final archivedProjectIndex = archivedProjects.indexWhere((p) => p.id == projectId);

      if (archivedProjectIndex != -1) {
        // Move from archived to active
        final archivedProject = archivedProjects[archivedProjectIndex];
        await _archivedProjectsBox.delete(archivedProject.key);
        archivedProject.updateLastEdited();
        await _projectsBox.add(archivedProject);

        // Invalidate both caches
        _cachedProjects = null;
        _cachedArchivedProjects = null;

        notifyListeners();
        return;
      }

      throw Exception('Project not found for archive toggle: $projectId');
    } catch (e) {
      debugPrint('Error toggling archive status: $e');
      throw Exception('Error toggling archive status: $e');
    }
  }
}