import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/local_storage/local_storage.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:projekt_hive/screens/home/view/home_screen.dart';
import 'package:projekt_hive/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => ProjectRepository(
        projectApi: ProjectLocalStorage(),
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
