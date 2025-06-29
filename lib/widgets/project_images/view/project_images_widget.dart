import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/widgets/project_images/project_images.dart';
import 'dart:convert';

class ProjectImagesWidget extends StatelessWidget {
  final Project project;
  final bool active;

  const ProjectImagesWidget({
    super.key,
    required this.project,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectImagesBloc(
        repository: context.read<ProjectRepository>(),
        project: project,
        active: active,
      ),
      child: const ProjectImagesView(),
    );
  }
}

class ProjectImagesView extends StatelessWidget {
  const ProjectImagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProjectImagesBloc>();

    return BlocBuilder<ProjectImagesBloc, ProjectImagesState>(
      builder: (context, state) {
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
            if (state.project.images.isEmpty)
              if (state.status == ProjectImagesStatus.loading)
                Center(child: CupertinoActivityIndicator())
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(CupertinoIcons.photo,
                            size: 48, color: CupertinoColors.systemGrey),
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
                          onPressed: () => _pickImage(bloc, context),
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
                itemCount: state.project.images.length,
                itemBuilder: (context, index) {
                  return _ImageTile(
                    imageData: state.project.images[index],
                    onDelete: () => _deleteImage(bloc, context, index),
                  );
                },
              ),
            if (state.project.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoButton.filled(
                  onPressed: () => _pickImage(bloc, context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.photo_camera),
                      SizedBox(width: 8),
                      Text('Foto hinzufügen'),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _deleteImage(ProjectImagesBloc bloc, BuildContext context, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Foto löschen'),
        content: const Text('Möchten Sie dieses Foto wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              bloc.add(ProjectImagesDeleteImage(index: index));
              Navigator.pop(context);
            },
            isDestructiveAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ProjectImagesBloc bloc, BuildContext context) async {
    final picker = ImagePicker();

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        bloc.add(ProjectImagesAddImage(image: base64Image));
      }
    } catch (e) {
      if (context.mounted) {
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
                          size: 40, color: CupertinoColors.systemGrey2),
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
              color: CupertinoColors.black.withAlpha(127),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 30,
              onPressed: onDelete,
              child: const Icon(CupertinoIcons.delete,
                  size: 20, color: CupertinoColors.white),
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
                      child: const Icon(CupertinoIcons.xmark,
                          color: CupertinoColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.trash,
                          color: CupertinoColors.destructiveRed),
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
                            size: 100, color: CupertinoColors.systemGrey),
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
