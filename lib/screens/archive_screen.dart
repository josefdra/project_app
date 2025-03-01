import 'package:flutter/material.dart';
import '../widgets/project_grid.dart';
import '../widgets/search_bar.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archiv'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              onSearch: (query) {
                // Implementiere Archiv-Suche
              },
            ),
          ),
        ),
      ),
      body: const ProjectGrid(archived: true),
    );
  }
}