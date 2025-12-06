import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app_module.dart';
import 'services/locale_provider.dart';
import 'services/app_initialization_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Install global error handlers FIRST to capture any initialization errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('UNCAUGHT FLUTTER ERROR: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT ASYNC ERROR: $error\n$stack');
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('DEBUG: Flutter binding initialized');
    
    // Initialize app services with robust error handling
    debugPrint('DEBUG: Starting app service initialization...');
    
    try {
      final appInitService = AppInitializationService();
      await appInitService.initialize();
      debugPrint('DEBUG: App services initialized successfully');
    } catch (e, st) {
      debugPrint('DEBUG: App initialization failed: $e\n$st');
      debugPrint('DEBUG: Continuing with app launch - services will initialize on-demand');
      // Continue anyway - services will initialize when needed
    }
    
    debugPrint('DEBUG: Launching Flutter app...');
    runApp(ModularApp(
      module: AppModule(),
      child: const AftenStatusApp(),
    ));
    
  } catch (e, st) {
    debugPrint('CRITICAL ERROR in main(): $e\n$st');
    
    // Emergency fallback: try to launch minimal app
    try {
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('App initialization failed'),
                const SizedBox(height: 8),
                Text('Error: $e', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ));
    } catch (criticalError) {
      debugPrint('CRITICAL: Cannot launch app at all: $criticalError');
    }
  }
}

/// Main application widget with locale support
class AftenStatusApp extends StatefulWidget {
  const AftenStatusApp({super.key});

  @override
  State<AftenStatusApp> createState() => _AftenStatusAppState();
}

class _AftenStatusAppState extends State<AftenStatusApp> {
  late LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _localeProvider = Modular.get<LocaleProvider>();
    _localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aften Status',
      theme: _buildTheme(),
      routerConfig: Modular.routerConfig,
      debugShowCheckedModeBanner: false,
      locale: _localeProvider.locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('da'),
      ],
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B4CCC), // Purple primary color
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
  }
}
