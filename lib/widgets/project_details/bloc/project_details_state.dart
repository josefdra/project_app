part of 'project_details_bloc.dart';

enum ProjectDetailsStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  error,
}

class ProjectDetailsState extends Equatable {
  const ProjectDetailsState({
    this.status = ProjectDetailsStatus.initial,
    required this.project,
    this.active = true,
    this.expandedItems = const <int>{},
  });

  final ProjectDetailsStatus status;
  final Project project;
  final bool active;
  final Set<int> expandedItems;

  ProjectDetailsState copyWith({
    ProjectDetailsStatus? status,
    Project? project,
    bool? active,
    Set<int>? expandedItems,
  }) {
    return ProjectDetailsState(
      status: status ?? this.status,
      project: project ?? this.project,
      active: active ?? this.active,
      expandedItems: expandedItems ?? this.expandedItems,
    );
  }

  @override
  List<Object?> get props => [
        status,
        project,
        active,
        expandedItems,
      ];
}
