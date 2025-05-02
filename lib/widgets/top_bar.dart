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
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset('assets/logo.png', height: 32),
              const SizedBox(width: 8),
              Text('BabyBerry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE44F8F),
                      )),
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
