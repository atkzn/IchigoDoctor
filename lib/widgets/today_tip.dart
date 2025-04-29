// lib/widgets/today_tip.dart
import 'package:flutter/material.dart';
import '../repositories/tip_repo.dart';

class TodayTip extends StatelessWidget {
  const TodayTip({super.key});
  @override
  Widget build(BuildContext context) {
    final idx = DateTime.now().day;      // 例：日付で簡易ローテ
    return FutureBuilder(
      future: TipRepo.load(),
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tips = snap.data!;
        final tip = tips[idx % tips.length];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb),
            title: Text(tip.title),
            subtitle: Text(tip.body),
          ),
        );
      },
    );
  }
}
