import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/screens/project_screen.dart';
import 'package:provider/provider.dart';

class ProjectGrid extends StatelessWidget {
  final bool active;
  final Iterable<Project> projects;

  const ProjectGrid({
    super.key,
    required this.active,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? CupertinoIcons.doc_text : CupertinoIcons.archivebox,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              active ? 'Keine aktiven Projekte' : 'Keine archivierten Projekte',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            if (active)
              CupertinoButton.filled(
                  onPressed: () => _showNewProjectDialog(context),
                  child: const Text('Neues Projekt erstellen')),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLargeScreen ? 3 : 2,
        childAspectRatio: isLargeScreen ? 1.15 : 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects.elementAt(index);
        return ProjectTile(project: project);
      },
    );
  }
}

void _showNewProjectDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  String errorText = '';

  showCupertinoDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return CupertinoAlertDialog(
          title: const Text('Neues Projekt'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Projektname',
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _createProject(context, value.trim());
                  } else {
                    setState(() {
                      errorText = 'Projektname darf nicht leer sein';
                    });
                  }
                },
              ),
              if (errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _createProject(context, name);
                } else {
                  setState(() {
                    errorText = 'Projektname darf nicht leer sein';
                  });
                }
              },
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    ),
  );
}

void _createProject(BuildContext context, String name) {
  final newProject = Project(name: name);
  context.read<ProjectRepository>().addProject(project: newProject);
  Navigator.pop(context);
  Navigator.of(context).push(ProjectScreen.route(project: newProject));
}

class ProjectTile extends StatelessWidget {
  const ProjectTile({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColorFromName(project.name);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () =>
          Navigator.of(context).push(ProjectScreen.route(project: project)),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(50),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.time,
                              size: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(project.lastEdited),
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: CupertinoColors.systemGrey.withOpacity(0.2),
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${project.items.length} ${project.items.length == 1 ? 'Position' : 'Positionen'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            if (project.images.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.photo,
                                    size: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${project.images.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.money_euro,
                                size: 16,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${project.totalPrice.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColorFromName(String name) {
    final colors = [
      CupertinoColors.systemGreen,
      CupertinoColors.systemBlue,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPink,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
    ];

    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
