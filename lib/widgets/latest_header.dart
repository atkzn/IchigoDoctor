import 'dart:io';
import 'package:flutter/material.dart';
import '../repositories/diary_repo.dart';

class LatestHeader extends StatelessWidget {
  const LatestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DiaryRepo.latest(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 写真がまだ無い場合は従来キャラのみ
          return Center(
            child: Image.asset('assets/characters/fairy.png', height: 200),
          );
        }
        final diary = snapshot.data!;
        return AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ユーザー最新写真
              Image.file(
                File(diary.image),
                fit: BoxFit.cover,
              ),
              // キャラを右下 1/8 サイズで重ねる
              Positioned(
                right: 8,
                bottom: 8,
                child: FractionallySizedBox(
                  widthFactor: 0.2,   // =1/5。お好みで 0.125 など
                  child: Image.asset('assets/characters/fairy.png'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
