import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/project.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/project_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ProjectItemAdapter());

  await Hive.openBox<Project>('projects');
  await Hive.openBox<Project>('archived_projects');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'Projekt App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('de'),
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/archive': (context) => const ArchiveScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/project') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ProjectScreen(
                projectId: args['projectId'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}