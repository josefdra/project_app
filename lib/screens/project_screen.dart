import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/project_details.dart';
import '../widgets/project_images.dart';
import '../services/pdf_service.dart';

class ProjectScreen extends StatelessWidget {
  final String projectId;

  const ProjectScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.getProjectById(projectId);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate),
                onPressed: () async {
                  final picker = ImagePicker();
                  try {
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final base64Image = base64Encode(bytes);
                      project.images.add(base64Image);
                      provider.updateProject(project);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fehler beim Laden des Bildes')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => PDFService.generatePDF(project),
              ),
              IconButton(
                icon: Icon(
                  provider.archivedProjects.contains(project)
                      ? Icons.unarchive
                      : Icons.archive,
                ),
                onPressed: () => provider.toggleArchiveStatus(projectId),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                ProjectDetails(project: project),
                ProjectImages(project: project),
              ],
            ),
          ),
        );
      },
    );
  }
}