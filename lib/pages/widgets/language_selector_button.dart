import 'package:flutter/material.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const List<LanguageOption> defaults = [
    LanguageOption(code: 'en', name: 'English', flag: '🇬🇧'),
    LanguageOption(code: 'da', name: 'Dansk', flag: '🇩🇰'),
  ];
}

class LanguageSelectorButton extends StatelessWidget {
  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSelectorButton({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentOption = LanguageOption.defaults.firstWhere(
      (opt) => opt.code == currentLanguageCode,
      orElse: () => LanguageOption.defaults.first,
    );

    return PopupMenuButton<String>(
      icon: Text(currentOption.flag, style: const TextStyle(fontSize: 24)),
      onSelected: onLanguageChanged,
      itemBuilder: (context) => LanguageOption.defaults.map((lang) {
        return PopupMenuItem(
          value: lang.code,
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
  }
}
