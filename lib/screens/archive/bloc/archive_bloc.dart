import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:projekt_hive/general/search_query.dart';
import 'package:stream_transform/stream_transform.dart';

part 'archive_event.dart';
part 'archive_state.dart';

class ArchiveBloc extends Bloc<ArchiveEvent, ArchiveState> {
  ArchiveBloc({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository,
        super(const ArchiveState()) {
    on<ArchiveSubscriptionRequested>(_onSubscriptionRequested);
    on<ArchiveProjectsUpdate>(_onProjectsUpdate);
    on<ArchiveSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }

  final ProjectRepository _projectRepository;
  late final StreamSubscription<List<Project>>? _projectSubscription;

  Future<void> _onSubscriptionRequested(
    ArchiveSubscriptionRequested event,
    Emitter<ArchiveState> emit,
  ) async {
    emit(state.copyWith(status: ArchiveStatus.loading));

    _projectSubscription = _projectRepository.archivedProjects.listen(
      (projects) => add(ArchiveProjectsUpdate(projects)),
    );
  }

  void _onProjectsUpdate(
    ArchiveProjectsUpdate event,
    Emitter<ArchiveState> emit,
  ) {
    emit(state.copyWith(status: ArchiveStatus.success, projects: event.projects));
  }

  void _onSearchQueryChanged(
    ArchiveSearchQueryChanged event,
    Emitter<ArchiveState> emit,
  ) {
    emit(
      state.copyWith(searchQuery: SearchQuery(searchQuery: event.searchQuery)),
    );
  }

  @override
  Future<void> close() async {
    await _projectSubscription?.cancel();
    return super.close();
  }
}
