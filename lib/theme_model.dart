import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  void toggle() {
    mode = (mode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
