import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';

part 'edit_name_event.dart';
part 'edit_name_state.dart';

class EditNameBloc extends Bloc<EditNameEvent, EditNameState> {
  EditNameBloc(this.project, this.active, this.repository)
      : controller = TextEditingController(text: project.name),
        super(EditNameState()) {
    on<EditNameTextChanged>(_onTextChanged);
    on<EditNameValidation>(_onValidation);
  }

  final TextEditingController controller;
  final Project project;
  final bool active;
  final ProjectRepository repository;

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

    emit(
      state.copyWith(
        validationErrors: validationErrors,
        status: validationErrors.isNotEmpty
            ? EditNameStatus.invalid
            : EditNameStatus.success,
      ),
    );

    repository.updateProject(
      project: project.copyWith(name: state.text),
      active: active,
    );
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
