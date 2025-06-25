import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';

part 'project_images_event.dart';
part 'project_images_state.dart';

class ProjectImagesBloc extends Bloc<ProjectImagesEvent, ProjectImagesState> {
  ProjectImagesBloc(
      {required this.repository, required Project project, required bool active})
      : super(ProjectImagesState(project: project, active: active)) {
    on<ProjectImagesAddImage>(_onAddImage);
    on<ProjectImagesDeleteImage>(_onDeleteImage);
  }

  final ProjectRepository repository;

  void _onAddImage(
    ProjectImagesAddImage event,
    Emitter<ProjectImagesState> emit,
  ) {
    final updatedImages = [...state.project.images];
    updatedImages.add(event.image);

    final updatedProject = state.project.copyWith(images: updatedImages);

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }

  Future<void> _onDeleteImage(
    ProjectImagesDeleteImage event,
    Emitter<ProjectImagesState> emit,
  ) async {
    final updatedImages = [...state.project.images];
    updatedImages.removeAt(event.index);

    final updatedProject = state.project.copyWith(images: updatedImages);

    repository.updateProject(active: state.active, project: updatedProject);
    emit(state.copyWith(project: updatedProject));
  }
}
