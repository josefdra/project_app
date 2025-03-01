import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
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
  // Keep track of whether the screen is active
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // Check if project exists after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProjectExists();
    });
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }

  // Safely check if project exists
  void _checkProjectExists() {
    if (!mounted || !_isActive) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final project = provider.getProjectById(widget.projectId);

    if (project == null && mounted && _isActive) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.getProjectById(widget.projectId);

        if (project == null) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Laden...'),
            ),
            child: SafeArea(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          );
        }

        final isArchived = provider.archivedProjects.any((p) => p.id == widget.projectId);

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(project.name),
            leading: CupertinoNavigationBarBackButton(
              onPressed: () {
                if (mounted && _isActive) {
                  Navigator.of(context).pop();
                }
              },
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.doc_text),
                  onPressed: () {
                    if (mounted && _isActive) {
                      PDFService.generatePDF(project);
                    }
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    isArchived ? CupertinoIcons.tray_arrow_up : CupertinoIcons.archivebox,
                  ),
                  onPressed: () {
                    if (mounted && _isActive) {
                      _toggleArchiveStatus(provider, isArchived);
                    }
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis),
                  onPressed: () {
                    if (mounted && _isActive) {
                      _showActionSheet(context, project, provider, isArchived);
                    }
                  },
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
      },
    );
  }

  // Handle archive toggle with proper state checking
  Future<void> _toggleArchiveStatus(ProjectProvider provider, bool isArchived) async {
    try {
      await provider.toggleArchiveStatus(widget.projectId);
      if (mounted && _isActive) {
        _showActionMessage(
            context,
            isArchived
                ? 'Projekt wurde wiederhergestellt'
                : 'Projekt wurde archiviert'
        );
      }
    } catch (e) {
      if (mounted && _isActive) {
        _showActionMessage(context, 'Fehler beim Ändern des Archivstatus');
      }
    }
  }

  // Simple action message dialog
  void _showActionMessage(BuildContext context, String message) {
    if (!mounted || !_isActive) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Auto-dismiss after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });

        return CupertinoAlertDialog(
          content: Text(message),
        );
      },
    );
  }

  // Show action sheet with proper state checking
  void _showActionSheet(BuildContext context, Project project, ProjectProvider provider, bool isArchived) {
    if (!mounted || !_isActive) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (actionContext) => CupertinoActionSheet(
        title: const Text('Projekt-Aktionen'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(actionContext);
              if (mounted && _isActive) {
                _showRenameDialog(context, project.name, provider);
              }
            },
            child: const Text('Umbenennen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(actionContext);
              if (mounted && _isActive) {
                PDFService.generatePDF(project);
              }
            },
            child: const Text('PDF erstellen'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(actionContext);
              if (mounted && _isActive) {
                _confirmDelete(context, provider);
              }
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
    );
  }

  void _confirmDelete(BuildContext context, ProjectProvider provider) {
    if (!mounted || !_isActive) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Projekt löschen'),
        content: const Text(
            'Sind Sie sicher, dass Sie dieses Projekt löschen möchten? '
                'Diese Aktion kann nicht rückgängig gemacht werden.'
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            isDestructiveAction: true,
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              // Close the dialog first
              Navigator.pop(dialogContext);

              // Mark as inactive to prevent further UI updates
              _isActive = false;

              // Navigate away first, then delete
              Navigator.of(context).pop();

              // Delete project after navigation completes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.deleteProject(widget.projectId);
              });
            },
            isDestructiveAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  // Show rename dialog with proper state checking
  void _showRenameDialog(BuildContext context, String currentName, ProjectProvider provider) {
    if (!mounted || !_isActive) return;

    final controller = TextEditingController(text: currentName);
    String errorText = '';

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) {
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
                onPressed: () => Navigator.pop(dialogContext),
                isDestructiveAction: true,
                child: const Text('Abbrechen'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.pop(dialogContext);

                    // Only proceed if we're still mounted
                    if (mounted && _isActive) {
                      final project = provider.getProjectById(widget.projectId);
                      if (project != null) {
                        project.name = newName;
                        provider.updateProject(project).then((_) {
                          if (mounted && _isActive) {
                            _showActionMessage(context, 'Projekt wurde umbenannt');
                          }
                        });
                      }
                    }
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
}