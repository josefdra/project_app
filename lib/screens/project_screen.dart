import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/project_details.dart';
import '../widgets/project_images.dart';
import '../services/pdf_service.dart';

class ProjectScreen extends StatefulWidget {
  final String projectId;

  const ProjectScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  @override
  void initState() {
    super.initState();

    // Make sure we have fresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        try {
          final project = provider.getProjectById(widget.projectId);
          final isArchived = provider.archivedProjects.any((p) => p.id == widget.projectId);

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(project.name),
              // Add a back button that safely handles navigation
              leading: CupertinoNavigationBarBackButton(
                onPressed: () {
                  // Use post-frame callback for safe navigation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop();
                  });
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.doc_text),
                    onPressed: () {
                      // Call PDF service in a safe way
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        PDFService.generatePDF(project);
                      });
                    },
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      isArchived ? CupertinoIcons.tray_arrow_up : CupertinoIcons.archivebox,
                    ),
                    onPressed: () {
                      // Toggle archive status in a safe way
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.toggleArchiveStatus(widget.projectId).then((_) {
                          // Show a confirmation message
                          _showActionMessage(
                              context,
                              isArchived
                                  ? 'Projekt wurde wiederhergestellt'
                                  : 'Projekt wurde archiviert'
                          );
                        });
                      });
                    },
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.ellipsis),
                    onPressed: () => _showActionSheet(context, project, provider, isArchived),
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProjectDetails(project: project),
                    ProjectImages(project: project),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          // Handle case where project doesn't exist
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Projekt nicht gefunden'),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle,
                        size: 64,
                        color: CupertinoColors.systemRed
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Projekt konnte nicht gefunden werden',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () {
                        // Use post-frame callback for safe navigation
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                        });
                      },
                      child: const Text('Zurück zur Übersicht'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  void _showActionSheet(BuildContext context, dynamic project, ProjectProvider provider, bool isArchived) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Projekt-Aktionen'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showRenameDialog(context, project.name, provider);
              },
              child: const Text('Umbenennen'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  PDFService.generatePDF(project);
                });
              },
              child: const Text('PDF erstellen'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(context, provider);
              },
              child: const Text('Löschen'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Abbrechen'),
          ),
        ),
      );
    });
  }

  void _showRenameDialog(BuildContext context, String currentName, ProjectProvider provider) {
    final controller = TextEditingController(text: currentName);
    String errorText = '';

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Projekt umbenennen'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: controller,
                  autofocus: true,
                  placeholder: 'Neuer Name',
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
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.pop(context);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        final project = provider.getProjectById(widget.projectId);
                        project.name = newName;
                        provider.updateProject(project).then((_) {
                          setState(() {}); // Refresh the UI
                          _showActionMessage(context, 'Projekt wurde umbenannt');
                        });
                      } catch (e) {
                        debugPrint('Error renaming project: $e');
                      }
                    });
                  } else {
                    setState(() {
                      errorText = 'Projektname darf nicht leer sein';
                    });
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProjectProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Projekt löschen'),
        content: const Text(
            'Sind Sie sicher, dass Sie dieses Projekt löschen möchten? '
                'Diese Aktion kann nicht rückgängig gemacht werden.'
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.deleteProject(widget.projectId).then((_) {
                  Navigator.pop(context); // Go back to previous screen after deletion
                });
              });
            },
            isDefaultAction: true,
            isDestructiveAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showActionMessage(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Auto-dismiss after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });

        return CupertinoAlertDialog(
          content: Text(message),
        );
      },
    );
  }
}