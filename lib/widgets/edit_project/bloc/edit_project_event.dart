part of 'edit_project_bloc.dart';

sealed class EditProjectEvent extends Equatable {
  const EditProjectEvent();

  @override
  List<Object> get props => [];
}

final class EditProjectSubscriptionRequested extends EditProjectEvent {
  const EditProjectSubscriptionRequested();
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

final class EditProjectValidation extends EditProjectEvent {
  const EditProjectValidation();
}
