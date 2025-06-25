import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';

part 'project_details_event.dart';
part 'project_details_state.dart';

class ProjectDetailsBloc
    extends Bloc<ProjectDetailsEvent, ProjectDetailsState> {
  ProjectDetailsBloc({
    required this.repository,
    required Project project,
    required bool active,
  })  : controller = TextEditingController(text: project.description),
        super(ProjectDetailsState(
          status: ProjectDetailsStatus.loaded,
          project: project,
          active: active,
        )) {
    on<ProjectDetailsDateUpdated>(_onDateUpdated);
    on<ProjectDetailsUpdateDescription>(_onUpdateDescription);
    on<ProjectDetailsItemToggled>(_onItemToggled);
    on<ProjectDetailsRemoveItem>(_onRemoveItem);
    on<ProjectDetailsExpandedItemsUpdated>(_onExpandedItemsUpdated);
    on<ProjectDetailsAddItem>(_onAddItem);
    on<ProjectDetailsUpdateItem>(_onUpdateItem);
  }

  final ProjectRepository repository;
  final TextEditingController controller;

  Future<void> _onDateUpdated(
    ProjectDetailsDateUpdated event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final updatedProject = state.project.copyWith(date: event.date);
    
    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }

  Future<void> _onUpdateDescription(
    ProjectDetailsUpdateDescription event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final description = controller.text.trim();
    final updatedProject = state.project.copyWith(description: description);

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }

  Future<void> _onItemToggled(
    ProjectDetailsItemToggled event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final newExpandedItems = Set<int>.from(state.expandedItems);

    if (newExpandedItems.contains(event.index)) {
      newExpandedItems.remove(event.index);
    } else {
      newExpandedItems.add(event.index);
    }

    emit(state.copyWith(expandedItems: newExpandedItems));
  }

  Future<void> _onRemoveItem(
    ProjectDetailsRemoveItem event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final newItems = [...state.project.items]..removeAt(event.index);
    final updatedProject = state.project.copyWith(items: newItems);
    final newExpandedItems = <int>{};

    for (final expandedIndex in state.expandedItems) {
      if (expandedIndex > event.index) {
        newExpandedItems.add(expandedIndex - 1);
      } else if (expandedIndex != event.index) {
        newExpandedItems.add(expandedIndex);
      }
    }

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(
      project: updatedProject,
      expandedItems: newExpandedItems,
    ));
  }

  Future<void> _onExpandedItemsUpdated(
    ProjectDetailsExpandedItemsUpdated event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    emit(state.copyWith(expandedItems: event.expandedItems));
  }

  Future<void> _onAddItem(
    ProjectDetailsAddItem event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final newItems = [...state.project.items, event.item];
    final updatedProject = state.project.copyWith(items: newItems);

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }

  Future<void> _onUpdateItem(
    ProjectDetailsUpdateItem event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final newItems = [...state.project.items];
    newItems[event.index] = event.item;
    final updatedProject = state.project.copyWith(items: newItems);

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }

  @override
  Future<void> close() async {
    controller.dispose();
    await super.close();
  }
}
