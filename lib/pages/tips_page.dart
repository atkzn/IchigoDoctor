// lib/pages/tips_page.dart

import 'package:flutter/material.dart';
import '../models/tip.dart';
import '../repositories/tip_repo.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('育て方ヒント')),
      body: FutureBuilder<List<Tip>>(
        future: TipRepo.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tips = snapshot.data!;
          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, i) {
              final t = tips[i];
              return ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(t.title),
                subtitle: Text(t.body),
              );
            },
          );
        },
      ),
    );
  }
}
