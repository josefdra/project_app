import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';

class ProjectGrid extends StatelessWidget {
  final bool archived;

  const ProjectGrid({
    super.key,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        // Get projects without triggering a rebuild
        final projects = archived ? provider.archivedProjects : provider.projects;

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  archived ? CupertinoIcons.archivebox : CupertinoIcons.doc_text,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  archived ? 'Keine archivierten Projekte' : 'Keine aktiven Projekte',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 24),
                if (!archived)
                  CupertinoButton.filled(
                      onPressed: () {
                        // Use a post-frame callback to avoid build issues
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showNewProjectDialog(context, provider);
                        });
                      },
                      child: const Text('Neues Projekt erstellen')
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectTile(project: project);
          },
        );
      },
    );
  }

  void _showNewProjectDialog(BuildContext context, ProjectProvider provider) {
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
                      _createProject(context, provider, value.trim());
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
                    _createProject(context, provider, name);
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

  void _createProject(BuildContext context, ProjectProvider provider, String name) {
    try {
      final newProject = Project(name: name);
      provider.addProject(newProject);

      // Close dialog
      Navigator.pop(context);

      // Wait for the frame to complete before navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(
          context,
          '/project',
          arguments: {'projectId': newProject.id},
        );
      });
    } catch (e) {
      debugPrint('Error creating project: $e');
    }
  }
}

class ProjectTile extends StatelessWidget {
  final Project project;

  const ProjectTile({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Use post-frame callback to avoid build issues during navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(
            context,
            '/project',
            arguments: {'projectId': project.id},
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${project.items.length} Positionen',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${project.totalPrice.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}