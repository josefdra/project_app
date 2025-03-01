import 'package:flutter/material.dart';
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
        final projects = archived ? provider.archivedProjects : provider.projects;

        if (projects.isEmpty) {
          return Center(
            child: Text(
              archived ? 'Keine archivierten Projekte' : 'Keine aktiven Projekte',
              style: Theme.of(context).textTheme.titleLarge,
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
}

class ProjectTile extends StatelessWidget {
  final Project project;

  const ProjectTile({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/project',
          arguments: {'projectId': project.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                project.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${project.items.length} Positionen',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${project.totalPrice.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}