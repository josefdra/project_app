import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/project.dart';
import '../providers/project_provider.dart';
import 'package:provider/provider.dart';

class ProjectImages extends StatelessWidget {
  final Project project;

  const ProjectImages({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Fotos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (project.images.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Keine Fotos vorhanden'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: project.images.length + 1,
            itemBuilder: (context, index) {
              if (index == project.images.length) {
                return _AddImageButton(project: project);
              }
              return _ImageTile(
                imageData: project.images[index],
                onDelete: () => _deleteImage(context, index),
              );
            },
          ),
      ],
    );
  }

  void _deleteImage(BuildContext context, int index) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    project.images.removeAt(index);
    provider.updateProject(project);
  }
}

class _ImageTile extends StatelessWidget {
  final String imageData;
  final VoidCallback onDelete;

  const _ImageTile({
    required this.imageData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showFullImage(context),
            child: Image.memory(
              base64Decode(imageData),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.red,
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.memory(base64Decode(imageData)),
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final Project project;

  const _AddImageButton({
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _pickImage(context),
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate,
            size: 40,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    try {
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        project.images.add(base64Image);
        await projectProvider.updateProject(project);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Laden des Bildes'),
        ),
      );
    }
  }
}