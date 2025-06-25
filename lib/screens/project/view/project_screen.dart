import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/screens/project/bloc/project_bloc.dart';
import 'package:projekt_hive/widgets/edit_name/view/edit_name_widget.dart';
import 'package:projekt_hive/widgets/project_details/view/project_details_widget.dart';
import 'package:projekt_hive/widgets/project_images/view/project_images_widget.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({
    super.key,
    required this.project,
    required this.active,
  });

  final Project project;
  final bool active;

  static Route<void> route({required Project project, required bool active}) {
    return CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) => ProjectScreen(project: project, active: active),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProjectRepository>();
    return BlocProvider(
      create: (context) => ProjectBloc(
        projectRepository: repository,
        project: project,
        active: active,
      )..add(ProjectSubscriptionRequested()),
      child: ProjectView(repository: repository),
    );
  }
}

class ProjectView extends StatelessWidget {
  const ProjectView({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state.status == ProjectStatus.loading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(state.project.name),
            leading: CupertinoNavigationBarBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    state.active
                        ? CupertinoIcons.archivebox
                        : CupertinoIcons.tray_arrow_up,
                  ),
                  onPressed: () => context
                      .read<ProjectBloc>()
                      .add(const ProjectToggleArchivedStatus()),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis),
                  onPressed: () => showCupertinoModalPopup(
                    context: context,
                    builder: (actionContext) => CupertinoActionSheet(
                      title: const Text('Projekt-Aktionen'),
                      actions: <CupertinoActionSheetAction>[
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(actionContext);
                            showCupertinoDialog<EditNameWidget>(
                              context: context,
                              builder: (context) => EditNameWidget(
                                project: state.project,
                                active: state.active,
                                repository: repository,
                              ),
                            );
                          },
                          child: const Text('Umbenennen'),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.pop(actionContext);
                            showCupertinoDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: const Text('Projekt löschen'),
                                content: const Text(
                                    'Sind Sie sicher, dass Sie dieses Projekt löschen möchten? '
                                    'Diese Aktion kann nicht rückgängig gemacht werden.'),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Abbrechen'),
                                  ),
                                  CupertinoDialogAction(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.of(context).pop();
                                      context
                                          .read<ProjectBloc>()
                                          .add(const ProjectDeleteProject());
                                    },
                                    isDestructiveAction: true,
                                    child: const Text('Löschen'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Löschen'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.pop(actionContext);
                        },
                        child: const Text('Abbrechen'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ProjectDetailsWidget(
                      project: state.project, active: state.active),
                  ProjectImagesWidget(
                      project: state.project, active: state.active),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
