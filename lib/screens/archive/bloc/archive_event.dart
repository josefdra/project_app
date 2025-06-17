part of 'archive_bloc.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

sealed class ArchiveEvent extends Equatable {
  const ArchiveEvent();

  @override
  List<Object> get props => [];
}

final class ArchiveSubscriptionRequested extends ArchiveEvent {
  const ArchiveSubscriptionRequested();
}

class ArchiveProjectsUpdate extends ArchiveEvent {
  const ArchiveProjectsUpdate(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class ArchiveSearchQueryChanged extends ArchiveEvent {
  const ArchiveSearchQueryChanged(this.searchQuery);

  final String searchQuery;

  @override
  List<Object> get props => [searchQuery];
}
