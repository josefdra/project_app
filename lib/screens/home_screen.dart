import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_grid.dart';
import '../widgets/search_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekt App'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              onSearch: (query) {
                Provider.of<ProjectProvider>(context, listen: false)
                    .searchProjects(query);
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () => Navigator.pushNamed(context, '/archive'),
          ),
        ],
      ),
      body: const ProjectGrid(archived: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Projekt'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Projektname',
          ),
          onSubmitted: (value) => _createProject(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final textField = context.findRenderObject() as RenderBox;
              _createProject(context, textField.toString());
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _createProject(BuildContext context, String name) {
    if (name.isNotEmpty) {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      provider.addProject(Project(name: name));
      Navigator.pop(context);
    }
  }
}
