
import 'package:flutter/material.dart';

class AdviceCard extends StatelessWidget {
  final List<String> tips;
  const AdviceCard({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW * 2 / 3 - 32; // 左右余白16*2除外

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ── 左 2/3 : カード ──
          SizedBox(
            width: cardW,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('お世話アドバイス',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            )),
                    const SizedBox(height: 8),
                    ...tips.map(
                      (t) => Text('• $t',
                          style: TextStyle(
                              height: 1.6, color: colorScheme.onSurface)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── 右 1/3 : キャラクター中央 ──
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/characters/fairy.png',
                width: 96,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
