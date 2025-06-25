import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc(
      {required this.projectRepository,
      required Project project,
      required bool active})
      : super(ProjectState(project: project, active: active)) {
    on<ProjectSubscriptionRequested>(_onSubscriptionRequested);
    on<ProjectProjectsUpdate>(_onProjectsUpdate);
    on<ProjectToggleArchivedStatus>(_onProjectToggleArchivedStatus);
    on<ProjectDeleteProject>(_onDeleteProject);
  }

  final ProjectRepository projectRepository;
  late final StreamSubscription<List<Project>>? _projectSubscription;

  Future<void> _onSubscriptionRequested(
    ProjectSubscriptionRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStatus.loading));

    _projectSubscription = state.active
        ? projectRepository.activeProjects
            .listen((projects) => add(ProjectProjectsUpdate(projects)))
        : projectRepository.archivedProjects
            .listen((projects) => add(ProjectProjectsUpdate(projects)));
  }

  void _onProjectsUpdate(
    ProjectProjectsUpdate event,
    Emitter<ProjectState> emit,
  ) {
    final projects =
        event.projects.where((p) => p.id == state.project.id).toList();

    if (projects.isNotEmpty) {
      emit(state.copyWith(
          status: ProjectStatus.success, project: projects.first));
    }
  }

  void _onProjectToggleArchivedStatus(
    ProjectToggleArchivedStatus event,
    Emitter<ProjectState> emit,
  ) {
    projectRepository.toggleArchiveStatus(
      project: state.project,
      active: state.active,
    );
    emit(state.copyWith(active: !state.active));
  }

  void _onDeleteProject(
    ProjectDeleteProject event,
    Emitter<ProjectState> emit,
  ) {
    projectRepository.deleteProject(
      project: state.project,
      active: state.active,
    );
  }

  @override
  Future<void> close() async {
    await _projectSubscription?.cancel();
    return super.close();
  }
}
