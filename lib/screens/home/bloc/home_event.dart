part of 'home_bloc.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeSubscriptionRequested extends HomeEvent {
  const HomeSubscriptionRequested();
}

class HomeProjectsUpdate extends HomeEvent {
  const HomeProjectsUpdate(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class HomeSearchQueryChanged extends HomeEvent {
  const HomeSearchQueryChanged(this.searchQuery);

  final String searchQuery;

  @override
  List<Object> get props => [searchQuery];
}
