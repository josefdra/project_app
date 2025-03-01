import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../widgets/project_grid.dart';
import '../providers/project_provider.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
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
        middle: const Text('Archiv'),
        // Add a back button that safely handles navigation
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            // Use post-frame callback for safe navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Archiv durchsuchen...',
                onChanged: (query) {
                  Provider.of<ProjectProvider>(context, listen: false)
                      .setSearchQuery(query);
                },
              ),
            ),
            const Expanded(
              child: ProjectGrid(archived: true),
            ),
          ],
        ),
      ),
    );
  }
}