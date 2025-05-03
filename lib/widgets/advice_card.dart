import 'package:flutter/material.dart';

class AdviceCard extends StatelessWidget {
  final List<String> tips;
  const AdviceCard({super.key, required this.tips});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 本体 ──
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: Padding(
              // 右側イラストぶん 80px 余白を確保
              padding: const EdgeInsets.fromLTRB(20, 20, 100, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('お世話アドバイス',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...tips.map(
                    (t) => Text('• $t',
                        style: const TextStyle(height: 1.6)),
                  ),
                ],
              ),
            ),
          ),

          // ── イラスト (カード外) ──
          Positioned(
            right: -20,  // カード外へ 20px
            bottom: -20, // シャドウの下にも少し出す
            child: Image.asset('assets/characters/fairy.png', width: 96),
          ),
        ],
      );
}
