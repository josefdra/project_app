import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_grid.dart';
import '../widgets/cloud_sync_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Make sure we have fresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Projekte'),
        leading: const CloudSyncIndicator(), // Add cloud sync indicator here
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.archivebox),
              onPressed: () {
                // Use post-frame callback to avoid build issues when navigating
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/archive')
                      .then((_) {
                    // Refresh data when returning from archive
                    Provider.of<ProjectProvider>(context, listen: false).refreshData();
                  });
                });
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: () => _showNewProjectDialog(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Suchen...',
                onChanged: (query) {
                  Provider.of<ProjectProvider>(context, listen: false)
                      .setSearchQuery(query);
                },
              ),
            ),
            const Expanded(
              child: ProjectGrid(archived: false),
            ),
          ],
        ),
      ),
    );
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
    try {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      final newProject = Project(name: name);

      // Close dialog
      Navigator.pop(context);

      // Create project and navigate in a safe way
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.addProject(newProject).then((_) {
          Navigator.pushNamed(
            context,
            '/project',
            arguments: {'projectId': newProject.id},
          );
        });
      });
    } catch (e) {
      debugPrint('Error creating project: $e');
    }
  }
}