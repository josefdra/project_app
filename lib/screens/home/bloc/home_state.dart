part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, error }

final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.projects = const [],
    this.searchQuery = const SearchQuery<Project>(),
  });

  final HomeStatus status;
  final List<Project> projects;
  final SearchQuery<Project> searchQuery;

  Iterable<Project> get searchQueryedProjects =>
      searchQuery.applyAll(projects);

  HomeState copyWith({
    HomeStatus? status,
    List<Project>? projects,
    SearchQuery<Project>? searchQuery,
  }) {
    return HomeState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props => [status, projects];
}
