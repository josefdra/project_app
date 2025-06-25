part of 'project_bloc.dart';

sealed class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object> get props => [];
}

final class ProjectSubscriptionRequested extends ProjectEvent {
  const ProjectSubscriptionRequested();
}

class ProjectProjectsUpdate extends ProjectEvent {
  const ProjectProjectsUpdate(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class ProjectToggleArchivedStatus extends ProjectEvent {
  const ProjectToggleArchivedStatus();
}

class ProjectDeleteProject extends ProjectEvent {
  const ProjectDeleteProject();
}
