import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/screens/archive/bloc/archive_bloc.dart';
import 'package:projekt_hive/widgets/project_grid.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  static Route<void> route() {
    return CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) => const ArchiveScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ArchiveBloc(projectRepository: context.read<ProjectRepository>())
            ..add(const ArchiveSubscriptionRequested()),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Archiv'),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoNavigationBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        child: const ArchiveView(),
      ),
    );
  }
}

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArchiveBloc, ArchiveState>(
      builder: (context, state) {
        if (state.projects.isEmpty) {
          if (state.status == ArchiveStatus.loading) {
            return const Center(child: CupertinoActivityIndicator());
          } else {
            return Center(
              child: Text('Keine archivierten Projekte'),
            );
          }
        }

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSearchTextField(
                  placeholder: 'Suchen...',
                  onChanged: (query) {
                    context
                        .read<ArchiveBloc>()
                        .add(ArchiveSearchQueryChanged(query));
                  },
                ),
              ),
              Expanded(
                child: ProjectGrid(
                    projects: state.searchQueryedProjects, active: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
