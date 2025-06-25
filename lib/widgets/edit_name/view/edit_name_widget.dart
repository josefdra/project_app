import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/widgets/edit_name/bloc/edit_name_bloc.dart';

class EditNameWidget extends StatelessWidget {
  const EditNameWidget({
    super.key,
    required this.project,
    required this.active, 
    required this.repository,
  });

  final Project project;
  final bool active;
  final ProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditNameBloc(project, active, repository),
      child: const EditNameView(),
    );
  }
}

class EditNameView extends StatelessWidget {
  const EditNameView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditNameBloc, EditNameState>(
      builder: (context, state) {
        if (state.status == EditNameStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CupertinoAlertDialog(
          title: const Text('Projekt umbenennen'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const _TextField(),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context.read<EditNameBloc>().add(const EditNameValidation());

                if (state.validationErrors.isEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditNameBloc>().state;
    final hintText = 'Projektname';
    final error = state.validationErrors['text'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.status.isLoadingOrSuccess)
          Padding(padding: const EdgeInsets.only(bottom: 8.0)),
        CupertinoTextField(
          controller: context.read<EditNameBloc>().controller,
          key: const Key('editProjectView_text_textFormField'),
          enabled: !state.status.isLoadingOrSuccess,
          placeholder: hintText,
          maxLength: 50,
          maxLines: 1,
          inputFormatters: [
            LengthLimitingTextInputFormatter(300),
          ],
          decoration: BoxDecoration(
            border: Border.all(
              color: error != null
                  ? CupertinoColors.destructiveRed.resolveFrom(context)
                  : CupertinoColors.separator.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          onChanged: (value) {
            context.read<EditNameBloc>().add(EditNameTextChanged(value));
          },
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              error,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoColors.destructiveRed.resolveFrom(context),
                    fontSize: 12,
                  ),
            ),
          ),
      ],
    );
  }
}
