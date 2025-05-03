import 'package:flutter/material.dart';

class StageStatusCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const StageStatusCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3C362C)   // 暗ベージュ
            : const Color(0xFFF2E8D7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '生育ステージ ${d['stage'].substring(1)}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 8),
            _row(context,'🌱 生育日数', '${d['growthDaysEst']}日'),
            _row(context,'🌼 開花まであと', '${d['daysToFlower']}日'),
            _row(context,'🍓 収穫まであと', '${d['daysToHarvest']}日'),
            _row(context,'❤️ 状態', d['growthStatus']),
            _row(context,'🏥 病気', d['disease']),
          ],
        ),
      );

  /// 1 行（ラベル＋値）をテーマに応じた色で描画
  Widget _row(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      color: cs.onSurface,          // ← ダークなら明色、ライトなら暗色
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: textStyle),
        ],
      ),
    );
  }
}
