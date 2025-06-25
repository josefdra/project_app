part of 'project_images_bloc.dart';

sealed class ProjectImagesEvent extends Equatable {
  const ProjectImagesEvent();

  @override
  List<Object> get props => [];
}

final class ProjectImagesSubscriptionRequested extends ProjectImagesEvent {
  const ProjectImagesSubscriptionRequested();
}

final class ProjectImagesAddImage extends ProjectImagesEvent {
  const ProjectImagesAddImage({required this.image});

  final String image;

  @override
  List<Object> get props => [image];
}

final class ProjectImagesDeleteImage extends ProjectImagesEvent {
  const ProjectImagesDeleteImage({required this.index});

  final int index;

  @override
  List<Object> get props => [index];
}
