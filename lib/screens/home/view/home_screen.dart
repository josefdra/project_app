import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/repository/project_repository.dart';
import 'package:projekt_hive/screens/archive/view/archive_screen.dart';
import 'package:projekt_hive/screens/home/bloc/home_bloc.dart';
import 'package:projekt_hive/widgets/edit_project/view/edit_project_widget.dart';
import 'package:projekt_hive/widgets/project_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static Route<void> route() {
    return CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) => const HomeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        projectRepository: context.read<ProjectRepository>(),
      )..add(const HomeSubscriptionRequested()),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Projekte'),
          trailing: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.archivebox),
                onPressed: () => Navigator.of(context).push(
                  ArchiveScreen.route(),
                ),
              ),
              CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.add),
                  onPressed: () => showCupertinoDialog<EditProjectWidget>(
                      context: context,
                      builder: (context) => const EditProjectWidget())),
            ],
          ),
        ),
        child: const HomeView(),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.projects.isEmpty) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: CupertinoActivityIndicator());
          } else {
            return Center(
              child: Text('Keine aktiven Projekte'),
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
                    context.read<HomeBloc>().add(HomeSearchQueryChanged(query));
                  },
                ),
              ),
              Expanded(
                child: ProjectGrid(
                  projects: state.searchQueryedProjects,
                  active: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
