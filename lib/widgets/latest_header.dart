import 'dart:io';
import 'package:flutter/material.dart';
import '../repositories/diary_repo.dart';

/// ─────────────────────────────────────────────────────────────
/// 最新撮影写真ヘッダ
///   • アスペクト 1:1（正方形）
///   • 左右に 16 px 余白
///   • 角丸 12 px
///   • 写真が無い場合は撮影ガイド文を表示
/// ─────────────────────────────────────────────────────────────
class LatestHeader extends StatelessWidget {
  const LatestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // ❶ 直近 1 件の Diary レコードを取得
    return FutureBuilder(
      future: DiaryRepo.latest(),
      builder: (context, snapshot) {
        final diary = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),   // ←左右余白
          child: AspectRatio(
            aspectRatio: 1,                                      // ←正方形
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ❷ 背景：写真 or プレースホルダー
                  if (diary != null)
                    Image.file(File(diary.image), fit: BoxFit.cover)
                  else
                    Container(color: const Color(0xFFEFEFEF)),

                  // ❸ 写真が無い時だけ中央にガイド
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
            ),
          ),
        );
      },
    );
  }
}
