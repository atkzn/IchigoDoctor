// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/latest_notifier.dart';
import '../widgets/latest_header.dart';
import '../widgets/stage_status_card.dart';
import '../widgets/advice_card.dart';
import '../notifiers/theme_notifier.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //throw Exception('force crash');
    final diary = context.watch<LatestNotifier>().latest;

    // 撮影前はダミーデータ
    final dummy = {
      'stage': 'S0',
      'growthDaysEst': '-',
      'daysToFlower': '-',
      'daysToHarvest': '-',
      'growthStatus': '—',
      'disease': '—',
      'careTips': ['まず撮影ボタンで診断しましょう'],
    };

    final data = diary?.result ?? dummy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BabyBerry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () =>
                context.read<ThemeNotifier>().toggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          LatestHeader(),
          const SizedBox(height: 12),
          StageStatusCard(data: data),
          const SizedBox(height: 12),
          AdviceCard(tips: List<String>.from(data['careTips'])),
        ],
      ),
    );
  }
}
