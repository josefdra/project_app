part of 'project_bloc.dart';

sealed class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object> get props => [];
}

class ProjectToggleArchivedStatus extends ProjectEvent {
  const ProjectToggleArchivedStatus();
}

class ProjectDeleteProject extends ProjectEvent {
  const ProjectDeleteProject();
}
