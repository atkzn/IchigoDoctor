import 'package:flutter/material.dart';

class ColorNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const ColorNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF60C020),
      Color(0xFFFFB938),
      Color(0xFFE64A93),
      Color(0xFF1DA1F2),
      Color(0xFFFF9EA7),
    ];
    const icons = [
      Icons.home,
      Icons.camera_alt,
      Icons.book,
      Icons.lightbulb,
      Icons.settings,
    ];
    const labels = ['Home', 'Camera', 'Diary', 'Tips', '設定'];

    return Row(
      children: List.generate(5, (i) {
        final selected = i == index;
        return Expanded(
          child: InkWell(
            onTap: () => onTap(i),
            child: Container(
              height: 64,
              color: colors[i],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[i],
                      color: selected ? Colors.white : Colors.white70),
                  Text(labels[i],
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
