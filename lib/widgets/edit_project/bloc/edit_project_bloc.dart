import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'edit_project_event.dart';
part 'edit_project_state.dart';

class EditProjectBloc extends Bloc<EditProjectEvent, EditProjectState> {
  EditProjectBloc() : super(EditProjectState()) {
    on<EditProjectSubscriptionRequested>(_onSubscriptionRequested);
    on<EditProjectTextChanged>(_onTextChanged);
    on<EditProjectValidation>(_onValidation);
  }

  void _onSubscriptionRequested(
    EditProjectSubscriptionRequested event,
    Emitter<EditProjectState> emit,
  ) {
    emit(state.copyWith(status: EditProjectStatus.loading));
  }

  void _onTextChanged(
    EditProjectTextChanged event,
    Emitter<EditProjectState> emit,
  ) {
    final updatedErrors = Map<String, String?>.from(state.validationErrors)
      ..remove(event.fieldName);

    emit(state.copyWith(validationErrors: updatedErrors, text: event.text));
  }

  Map<String, String?> _validateFields() {
    final errors = <String, String?>{};

    if (state.text == '') {
      errors['text'] = 'Text darf nicht leer sein';
    }

    return errors;
  }

  Future<void> _onValidation(
    EditProjectValidation event,
    Emitter<EditProjectState> emit,
  ) async {
    final validationErrors = _validateFields();

    if (validationErrors.isNotEmpty) {
      emit(
        state.copyWith(
          validationErrors: validationErrors,
          status: EditProjectStatus.invalid,
        ),
      );
      return;
    }
  }
}
