import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../services/locale_provider.dart';
import 'language_selector_button.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final bool showSettings;
  final bool showLanguageSelector;
  final bool showGraph;
  final VoidCallback? onSettingsReturn;

  const CommonAppBar({
    super.key,
    required this.title,
    this.additionalActions,
    this.showSettings = false,
    this.showLanguageSelector = true,
    this.showGraph = false,
    this.onSettingsReturn,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (showGraph)
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Modular.to.pushNamed('/graph');
            },
            tooltip: 'Graph',
          ),
        if (showLanguageSelector)
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 100,
                  kToolbarHeight,
                  0,
                  0,
                ),
                items: LanguageOption.defaults.map((lang) {
                  return PopupMenuItem(
                    value: lang.code,
                    onTap: () {
                      final localeProvider = Modular.get<LocaleProvider>();
                      localeProvider.changeLocale(Locale(lang.code));
                    },
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(lang.name),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            tooltip: 'Change Language',
          ),
        if (additionalActions != null) ...additionalActions!,
        if (showSettings)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Modular.to.pushNamed('/settings');
              onSettingsReturn?.call();
            },
            tooltip: 'Settings',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
