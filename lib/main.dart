import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projekt_app/services/auto_backup_service.dart';
import 'package:projekt_app/services/backup_manager.dart';
import 'package:provider/provider.dart';
import 'models/project.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/project_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ProjectItemAdapter());

  // Open boxes
  await Hive.openBox<Project>('projects');
  await Hive.openBox<Project>('archived_projects');

  final autoBackupService = AutoBackupService();
  final backupManager = BackupManager();

// Check if auto backup is due
  autoBackupService.isAutoBackupDue().then((isDue) async {
    if (isDue) {
      // Run backup in background
      try {
        // Create cloud backup without showing UI
        final success = await backupManager.createCloudBackup(null);

        if (success) {
          // Update last auto backup date
          await autoBackupService.setLastAutoBackupDate(DateTime.now());
        }
      } catch (e) {
        debugPrint('Auto backup failed: $e');
        // We don't show errors for auto backup to avoid disrupting the user
      }
    }
  });

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
      child: CupertinoApp(
        title: 'Projekt App',
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('de'),
          Locale('en'),
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/archive': (context) => const ArchiveScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/project') {
            final args = settings.arguments as Map<String, dynamic>;
            return CupertinoPageRoute(
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