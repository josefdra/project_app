import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc(
      {required ProjectRepository projectRepository,
      required Project project,
      required bool active})
      : _projectRepository = projectRepository,
        super(ProjectState(project: project, active: active)) {
    on<ProjectToggleArchivedStatus>(_onProjectToggleArchivedStatus);
    on<ProjectDeleteProject>(_onDeleteProject);
  }

  final ProjectRepository _projectRepository;

  void _onProjectToggleArchivedStatus(
    ProjectToggleArchivedStatus event,
    Emitter<ProjectState> emit,
  ) {
    _projectRepository.toggleArchiveStatus(
      project: state.project,
      active: state.active,
    );
    emit(state.copyWith(active: !state.active));
  }

  void _onDeleteProject(
    ProjectDeleteProject event,
    Emitter<ProjectState> emit,
  ) {
    _projectRepository.toggleArchiveStatus(
      project: state.project,
      active: state.active,
    );
    emit(state.copyWith(active: !state.active));
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}
