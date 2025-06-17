import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/local_storage/local_storage.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:project_hive_backend/sync/sync.dart';
import 'package:projekt_hive/screens/home/view/home_screen.dart';
import 'package:projekt_hive/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes
  await Hive.openBox<Project>('projects');
  await Hive.openBox<Project>('archived_projects');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => ProjectRepository(
        projectApi: ProjectLocalStorage(),
        projectSyncService: ProjectSyncService(),
      ),
      dispose: (repository) => repository.dispose(),
      lazy: false,
      child: CupertinoApp(
        title: 'Projekt App',
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
