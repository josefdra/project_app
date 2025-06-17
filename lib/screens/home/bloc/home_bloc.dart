import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:projekt_hive/general/search_query.dart';
import 'package:stream_transform/stream_transform.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository,
        super(const HomeState()) {
    on<HomeSubscriptionRequested>(_onSubscriptionRequested);
    on<HomeProjectsUpdate>(_onProjectsUpdate);
    on<HomeSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }

  final ProjectRepository _projectRepository;
  late final StreamSubscription<List<Project>>? _projectSubscription;

  Future<void> _onSubscriptionRequested(
    HomeSubscriptionRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    _projectSubscription = _projectRepository.activeProjects.listen(
      (projects) => add(HomeProjectsUpdate(projects)),
    );
  }

  void _onProjectsUpdate(
    HomeProjectsUpdate event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(projects: event.projects));
  }

  void _onSearchQueryChanged(
    HomeSearchQueryChanged event,
    Emitter<HomeState> emit,
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
