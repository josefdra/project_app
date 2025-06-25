part of 'project_images_bloc.dart';

enum ProjectImagesStatus { initial, loading, ready, success, invalid, failure }

extension ProjectImagesStatusX on ProjectImagesStatus {
  bool get isLoadingOrSuccess => [
        ProjectImagesStatus.loading,
        ProjectImagesStatus.success,
      ].contains(this);
}

final class ProjectImagesState extends Equatable {
  const ProjectImagesState({
    this.status = ProjectImagesStatus.initial,
    required this.project,
    required this.active,
  });

  final ProjectImagesStatus status;
  final Project project;
  final bool active;

  ProjectImagesState copyWith({
    ProjectImagesStatus? status,
    Project? project,
    bool? active,
  }) {
    return ProjectImagesState(
      status: status ?? this.status,
      project: project ?? this.project,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [status, project, active];
}
