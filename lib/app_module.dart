import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/foundation.dart';

// Services
import 'services/storage_service.dart';
import 'services/settings_service.dart';
import 'services/field_definition_service.dart';
import 'services/locale_provider.dart';
import 'services/home_controller.dart';
import 'services/add_entry_controller.dart';
import 'services/settings_controller.dart';
import 'services/evening_status_drive_service.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/add_entry_page.dart';
import 'pages/settings_page.dart';
import 'pages/google_drive_sync_page.dart';
import 'pages/field_management_page.dart';
import 'pages/graph_page.dart';

class AppModule extends Module {
  // Static instance for locale provider to ensure singleton behavior
  static final LocaleProvider _localeProvider = LocaleProvider();
  
  @override
  void binds(i) {
    debugPrint('DEBUG: Binding services...');
    
    // Core services as singletons
    i.addSingleton<LocaleProvider>(() {
      debugPrint('DEBUG: Creating LocaleProvider...');
      // Initialize asynchronously - will load saved locale
      _localeProvider.initialize();
      return _localeProvider;
    });
    
    i.addSingleton<StorageService>(() {
      debugPrint('DEBUG: Creating StorageService...');
      final storageService = StorageService();
      storageService.init();
      return storageService;
    });
    
    i.addSingleton<FieldDefinitionService>(() {
      debugPrint('DEBUG: Creating FieldDefinitionService...');
      final service = FieldDefinitionService();
      return service;
    });
    
    i.addSingleton<SettingsService>(() {
      debugPrint('DEBUG: Creating SettingsService...');
      return SettingsService();
    });
    
    // Controllers (lazy singletons)
    i.addLazySingleton<HomeController>(HomeController.new);
    i.addLazySingleton<AddEntryController>(AddEntryController.new);
    i.addLazySingleton<SettingsController>(SettingsController.new);
    
    // Drive sync service (singleton instance)
    i.addSingleton<EveningStatusDriveService>(() => EveningStatusDriveService.instance);
  }

  @override
  void routes(r) {
    // Home routes
    r.child('/', child: (context) => const HomePage());
    r.child('/add-entry', child: (context) => const AddEntryPage());
    r.child('/edit-entry/:id', child: (context) => AddEntryPage(entryId: r.args.params['id']));
    
    // Graph route
    r.child('/graph', child: (context) => const GraphPage());
    
    // Settings routes
    r.child('/settings', child: (context) => const SettingsPage());
    r.child('/settings/google-drive', child: (context) => const GoogleDriveSyncPage());
    r.child('/settings/fields', child: (context) => const FieldManagementPage());
  }
}
