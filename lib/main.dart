import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:geo_economy_dashboard/common/services/offline_cache_service.dart';
import 'package:geo_economy_dashboard/common/services/network_service.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/features/settings/repos/settings_repo.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/router/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    AppLogger.warning('Firebase initialization failed', e);
    // Firebase 초기화 실패 시에도 앱은 계속 실행
  }

  // 오프라인 캐시 서비스 초기화
  try {
    await OfflineCacheService.instance.initialize();
    AppLogger.info('Offline cache service initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize offline cache service: $e');
  }

  // 네트워크 서비스 초기화
  try {
    await NetworkService.instance.initialize();
    AppLogger.info('Network service initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize network service: $e');
  }

  final preferences = await SharedPreferences.getInstance();
  final repository = SettingsRepository(preferences);

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => SettingsViewModel(repository)),
      ],
      child: const GeoEconomyDashboardApp(),
    ),
  );
}

class GeoEconomyDashboardApp extends ConsumerWidget {
  const GeoEconomyDashboardApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      title: 'Geo Economy Dashboard',
      themeMode: ref.watch(settingsProvider).darkmode
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: Typography.blackMountainView,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.background,
          surfaceTintColor: Color(0xFFECE6C2),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: Sizes.size20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          elevation: 2,
          color: AppColors.background,
        ),
        primaryColor: AppColors.primary,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: AppColors.textPrimary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
        listTileTheme: const ListTileThemeData(iconColor: AppColors.primary),
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: Typography.whiteMountainView,
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(
          foregroundColor: Color(0xFFECE6C2),
          backgroundColor: Colors.grey.shade900,
          surfaceTintColor: Colors.grey.shade900,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Color(0xFFECE6C2),
            fontSize: Sizes.size16 + Sizes.size2,
            fontWeight: FontWeight.w600,
          ),
          actionsIconTheme: IconThemeData(color: Color(0xFFECE6C2)),
          iconTheme: IconThemeData(color: Color(0xFFECE6C2)),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xFF212121)),
        primaryColor: const Color(0xFFFEA6F6),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFEA6F6),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade500,
        ),
        listTileTheme: const ListTileThemeData(iconColor: Colors.white),
      ),
    );
  }
}
