import 'package:flutter/material.dart';

class StageStatusCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const StageStatusCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF4EADB),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '生育ステージ ${d['stage'].substring(1)}',
              style: const TextStyle(
                  color: Color(0xFFE44F8F),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 8),
            _row('🌱 生育日数', '${d['growthDaysEst']}日'),
            _row('🌼 開花まであと', '${d['daysToFlower']}日'),
            _row('🍓 収穫まであと', '${d['daysToHarvest']}日'),
            _row('❤️ 状態', d['growthStatus']),
            _row('🏥 病気', d['disease']),
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}
