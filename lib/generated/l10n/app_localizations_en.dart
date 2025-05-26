// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StrawberryDoctor';

  @override
  String homeToday(Object day) {
    return 'Today is $day days!';
  }

  @override
  String waterReminder(Object time) {
    return 'Watering Reminder set at $time';
  }
}
