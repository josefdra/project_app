part of 'archive_bloc.dart';

enum ArchiveStatus { initial, loading, success, error }

final class ArchiveState extends Equatable {
  const ArchiveState({
    this.status = ArchiveStatus.initial,
    this.projects = const [],
    this.searchQuery = const SearchQuery<Project>(),
  });

  final ArchiveStatus status;
  final List<Project> projects;
  final SearchQuery<Project> searchQuery;

  Iterable<Project> get searchQueryedProjects => searchQuery.applyAll(projects);

  ArchiveState copyWith({
    ArchiveStatus? status,
    List<Project>? projects,
    SearchQuery<Project>? searchQuery,
  }) {
    return ArchiveState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props => [status, projects, searchQuery];
}
