import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'edit_name_event.dart';
part 'edit_name_state.dart';

class EditNameBloc extends Bloc<EditNameEvent, EditNameState> {
  EditNameBloc(String initialName)
      : controller = TextEditingController(text: initialName),
        super(EditNameState()) {
    on<EditNameSubscriptionRequested>(_onSubscriptionRequested);
    on<EditNameTextChanged>(_onTextChanged);
    on<EditNameValidation>(_onValidation);
  }

  final TextEditingController controller;

  void _onSubscriptionRequested(
    EditNameSubscriptionRequested event,
    Emitter<EditNameState> emit,
  ) {
    emit(state.copyWith(status: EditNameStatus.loading));
  }

  void _onTextChanged(
    EditNameTextChanged event,
    Emitter<EditNameState> emit,
  ) {
    final updatedErrors = Map<String, String?>.from(state.validationErrors)
      ..remove(event.fieldName);

    emit(state.copyWith(validationErrors: updatedErrors, text: event.text));
  }

  Map<String, String?> _validateFields() {
    final errors = <String, String?>{};

    if (state.text == '') {
      errors['text'] = 'Name darf nicht leer sein';
    }

    return errors;
  }

  Future<void> _onValidation(
    EditNameValidation event,
    Emitter<EditNameState> emit,
  ) async {
    final validationErrors = _validateFields();

    if (validationErrors.isNotEmpty) {
      emit(
        state.copyWith(
          validationErrors: validationErrors,
          status: EditNameStatus.invalid,
        ),
      );
      return;
    }
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
