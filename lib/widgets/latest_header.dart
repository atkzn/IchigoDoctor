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
        final diary = snapshot.data;

        // ヘッダ領域は 4:3 のアスペクトを維持
        return AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1) 背景：最新写真 or プレースホルダー ──
              if (diary != null)
                Image.file(File(diary.image), fit: BoxFit.cover)
              else
                Container(color: const Color(0xFFF5EEE4)), // 薄ベージュ

              // ── 2) キャラを右下に小さく ──
              Positioned(
                right: 8,
                bottom: 8,
                child: Image.asset(
                  'assets/characters/fairy.png',
                  width: 64,          // 固定 64px
                  fit: BoxFit.contain,
                ),
              ),

              // ── 3) 写真が無い時だけ中央に「撮影してね」ガイド ──
              if (diary == null)
                Center(
                  child: Text(
                    '📷 まずは撮影して診断しよう！',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
