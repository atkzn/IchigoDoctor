import 'package:flutter/material.dart';

class AdviceCard extends StatelessWidget {
  final List<String> tips;
  const AdviceCard({super.key, required this.tips});

  @override
  Widget build(BuildContext context) => Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('お世話アドバイス',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 8),
                    ...tips.map((t) =>
                        Text('• $t', style: const TextStyle(height: 1.5))),
                  ],
                ),
              //const SizedBox(width: 8),
              //Image.asset('assets/characters/fairy.png', width: 80),
              Positioned(
                right: -24,
                bottom: -24,
                child:
                    Image.asset('assets/characters/fairy.png', width: 96), // 影の外
              ),
            ],
          ),
        ),
      );
}
