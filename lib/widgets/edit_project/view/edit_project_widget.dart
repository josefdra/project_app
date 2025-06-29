import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:projekt_hive/screens/project/view/project_screen.dart';
import 'package:projekt_hive/widgets/edit_project/bloc/edit_project_bloc.dart';

class EditProjectWidget extends StatelessWidget {
  const EditProjectWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProjectBloc(context.read<ProjectRepository>()),
      child: const EditProjectView(),
    );
  }
}

class EditProjectView extends StatelessWidget {
  const EditProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditProjectBloc, EditProjectState>(
      builder: (context, state) {
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
                    .add(const EditProjectValidate());
                if (state.text.isNotEmpty) {
                  final p = Project(name: state.text);
                  context
                      .read<EditProjectBloc>()
                      .add(EditProjectCreate(project: p));
                  Navigator.of(context).pushReplacement(
                    ProjectScreen.route(project: p, active: true),
                  );
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
          ),
        CupertinoTextField(
          key: const Key('editProjectView_text_textFormField'),
          enabled: !state.status.isLoadingOrSuccess,
          placeholder: hintText,
          maxLength: 50,
          maxLines: 1,
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
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
