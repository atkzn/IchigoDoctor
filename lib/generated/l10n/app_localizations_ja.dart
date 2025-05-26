// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'いちごドクター';

  @override
  String homeToday(Object day) {
    return '今日は$day日目！';
  }

  @override
  String waterReminder(Object time) {
    return '水やりリマインダーを$timeに設定しました';
  }
}
