// lib/pages/root_page.dart
//
// Home / Camera / Diary / Tips / Settings を
// ColorNav で切り替えるページ
//
import 'package:flutter/material.dart';

import '../widgets/color_nav.dart';      // ★ ColorNav を使う
import 'home_page.dart';
import 'camera_page.dart';
import 'diary_page.dart';
import 'tips_page.dart';
import 'setting_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  late final _pages = [
    const HomePage(),
    const CameraPage(),
    const DiaryPage(),
    const TipsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        // ━━━ 下部ナビを ColorNav に置き換え ━━━
        bottomNavigationBar: ColorNav(
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      );
}
