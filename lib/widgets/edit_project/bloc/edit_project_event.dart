part of 'edit_project_bloc.dart';

sealed class EditProjectEvent extends Equatable {
  const EditProjectEvent();

  @override
  List<Object> get props => [];
}

final class EditProjectTextChanged extends EditProjectEvent {
  const EditProjectTextChanged(
    this.text, {
    this.fieldName = 'text',
  });

  final String fieldName;
  final String text;

  @override
  List<Object> get props => [text];
}

final class EditProjectValidate extends EditProjectEvent {
  const EditProjectValidate();
}

final class EditProjectCreate extends EditProjectEvent {
  const EditProjectCreate({required this.project});

  final Project project;

  @override
  List<Object> get props => [project];
}
