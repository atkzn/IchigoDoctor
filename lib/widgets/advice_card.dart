import 'package:flutter/material.dart';

/// お世話アドバイスカード
///   • 左右とも 16px 余白
///   • カード幅いっぱいに影付き
///   • イラストはカードの右外に 40px はみ出し、縦は中央寄せ
class AdviceCard extends StatelessWidget {
  final List<String> tips;
  const AdviceCard({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(                                // ← 左右余白
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─── 本体カード ───
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface,
            child: Padding(
              // 右側イラストぶん 110px 空ける
              padding: const EdgeInsets.fromLTRB(20, 20, 110, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'お世話アドバイス',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...tips.map(
                    (t) => Text(
                      '• $t',
                      style: TextStyle(
                        height: 1.6,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 右外イラスト ───
          Positioned(
            right: -40,                 // カード外へ 40px
            top: 40,                    // 縦方向ほぼ中央
            child: Image.asset(
              'assets/characters/fairy.png',
              width: 96,
            ),
          ),
        ],
      ),
    );
  }
}
