import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_model.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          color: const Color(0xFFF9F0EC),   // header 背景
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset('assets/logo.png', height: 32),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: () => context.read<ThemeModel>().toggle(),
              ),
            ],
          ),
        ),
      );
}
