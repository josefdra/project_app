import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:projekt_hive/screens/project_screen.dart';
import 'package:projekt_hive/widgets/edit_project/bloc/edit_project_bloc.dart';

class EditProjectWidget extends StatelessWidget {
  const EditProjectWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EditProjectBloc()..add(const EditProjectSubscriptionRequested()),
      child: BlocListener<EditProjectBloc, EditProjectState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            (current.status == EditProjectStatus.success),
        listener: (context, state) {
          Navigator.of(context).pop();
        },
        child: const EditProjectView(),
      ),
    );
  }
}

class EditProjectView extends StatelessWidget {
  const EditProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditProjectBloc, EditProjectState>(
      builder: (context, state) {
        if (state.status == EditProjectStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CupertinoAlertDialog(
          title: const Text('Neues Projekt'),
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
                context
                    .read<EditProjectBloc>()
                    .add(const EditProjectValidation());

                if (state.validationErrors.isEmpty) {
                  Navigator.of(context).pushReplacement(
                      ProjectScreen.route(project: Project(name: state.text)));
                }
              },
              child: const Text('Erstellen'),
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
    final state = context.watch<EditProjectBloc>().state;
    final hintText = 'Projektname';
    final error = state.validationErrors['text'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.status.isLoadingOrSuccess)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Projekt',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
            ),
          ),
        CupertinoTextField(
          key: const Key('editProjectView_text_textFormField'),
          enabled: !state.status.isLoadingOrSuccess,
          placeholder: hintText,
          maxLength: 300,
          maxLines: 7,
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
            context.read<EditProjectBloc>().add(EditProjectTextChanged(value));
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
