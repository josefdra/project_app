import 'package:flutter/cupertino.dart';
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Fotos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (project.images.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                      CupertinoIcons.photo,
                      size: 48,
                      color: CupertinoColors.systemGrey
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keine Fotos vorhanden',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () => _pickImage(context),
                    child: const Text('Foto hinzufügen'),
                  ),
                ],
              ),
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
            itemCount: project.images.length,
            itemBuilder: (context, index) {
              return _ImageTile(
                imageData: project.images[index],
                onDelete: () => _deleteImage(context, index),
              );
            },
          ),
        if (project.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoButton.filled(
              onPressed: () => _pickImage(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.photo_camera),
                  const SizedBox(width: 8),
                  const Text('Foto hinzufügen'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _deleteImage(BuildContext context, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Foto löschen'),
        content: const Text('Möchten Sie dieses Foto wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              project.images.removeAt(index);
              provider.updateProject(project);
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Optimize image size
        maxHeight: 1200,
        imageQuality: 85, // Reduce quality for smaller file sizes
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        project.images.add(base64Image);
        await projectProvider.updateProject(project);
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text('Fehler beim Laden des Bildes: ${e.toString()}'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showFullImage(context),
              child: Image.memory(
                base64Decode(imageData),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: CupertinoColors.systemGrey6,
                    child: const Center(
                      child: Icon(CupertinoIcons.photo_fill_on_rectangle_fill,
                          size: 40,
                          color: CupertinoColors.systemGrey2
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 30,
              child: const Icon(CupertinoIcons.delete, size: 20, color: CupertinoColors.white),
              onPressed: onDelete,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        color: CupertinoColors.black,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.memory(
                    base64Decode(imageData),
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(CupertinoIcons.photo,
                            size: 100,
                            color: CupertinoColors.systemGrey
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}