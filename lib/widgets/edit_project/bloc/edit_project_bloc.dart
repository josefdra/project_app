import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';

part 'edit_project_event.dart';
part 'edit_project_state.dart';

class EditProjectBloc extends Bloc<EditProjectEvent, EditProjectState> {
  EditProjectBloc(this.projectRepository) : super(EditProjectState()) {
    on<EditProjectTextChanged>(_onTextChanged);
    on<EditProjectValidate>(_onValidate);
    on<EditProjectCreate>(_onCreate);
  }

  ProjectRepository projectRepository;

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

  Future<void> _onValidate(
    EditProjectValidate event,
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
    }
  }

  Future<void> _onCreate(
    EditProjectCreate event,
    Emitter<EditProjectState> emit,
  ) async {
    projectRepository.addProject(project: event.project);
  }
}
