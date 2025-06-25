part of 'edit_name_bloc.dart';

sealed class EditNameEvent extends Equatable {
  const EditNameEvent();

  @override
  List<Object> get props => [];
}

final class EditNameTextChanged extends EditNameEvent {
  const EditNameTextChanged(
    this.text, {
    this.fieldName = 'text',
  });

  final String fieldName;
  final String text;

  @override
  List<Object> get props => [text];
}

final class EditNameValidation extends EditNameEvent {
  const EditNameValidation();
}
