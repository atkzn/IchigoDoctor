import 'package:flutter/material.dart';

class StageImage extends StatelessWidget {
  final String stage; // "S0"〜"S7"
  const StageImage({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    // マッピング
    const map = {
      'S0': 'assets/lottie/stage0.png',
      'S1': 'assets/lottie/stage1.png',
      'S2': 'assets/lottie/stage2.png',
      'S3': 'assets/lottie/stage3.png',
      'S4': 'assets/lottie/stage4.png',
      'S5': 'assets/lottie/stage5.png',
      'S6': 'assets/lottie/stage6.png',
      'S7': 'assets/lottie/stage7.png',
    };
    return Image.asset(map[stage] ?? map['S0']!,
        height: 120, fit: BoxFit.contain);
    /*
    final path = map[stage] ?? map['S0']!;
    return Image.asset(path, height: 120, fit: BoxFit.contain);
    */
  }
}
