import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'session.dart';

class Settings {
  const Settings({
    required this.localeCode,
    required this.themeMode,
    required this.countryCode,
  });

  final String localeCode;
  final ThemeMode themeMode;
  final String countryCode;

  Settings copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    String? countryCode,
  }) =>
      Settings(
        localeCode: localeCode ?? this.localeCode,
        themeMode: themeMode ?? this.themeMode,
        countryCode: countryCode ?? this.countryCode,
      );
}

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() {
    final prefs = ref.watch(prefsProvider);
    final themeMode = switch (prefs.getString('themeMode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return Settings(
      localeCode: prefs.getString('locale') ?? 'en',
      themeMode: themeMode,
      countryCode: prefs.getString('country') ?? 'EG',
    );
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await ref.read(prefsProvider).setString('locale', code);
  }

  Future<void> setCountry(String code) async {
    state = state.copyWith(countryCode: code);
    await ref.read(prefsProvider).setString('country', code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref.read(prefsProvider).setString('themeMode', stored);
  }
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(SettingsController.new);
