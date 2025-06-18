part of 'project_bloc.dart';

enum ProjectStatus { initial, loading, success, error }

final class ProjectState extends Equatable {
  const ProjectState({
    this.status = ProjectStatus.initial,
    required this.project,
    required this.active,
  });

  final ProjectStatus status;
  final Project project;
  final bool active;

  ProjectState copyWith({
    ProjectStatus? status,
    Project? project,
    bool? active,
  }) {
    return ProjectState(
      status: status ?? this.status,
      project: project ?? this.project,
      active: active ?? this.active,
    );
  }

  @override
  List<Object> get props => [status, project, active];
}
