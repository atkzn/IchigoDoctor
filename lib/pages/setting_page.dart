//
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final _privacyUrl = Uri.parse(
      'https://dadand-kikai.github.io/IchigoDoctor/privacy_policy');
  static final _termsUrl   = Uri.parse(
      'https://dadand-kikai.github.io/IchigoDoctor/terms_of_service');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('設定')),
        body: ListView(
          children: [
            ListTile(
              title: const Text('プライバシーポリシー'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(_privacyUrl,
                  mode: LaunchMode.externalApplication),
            ),
            ListTile(
              title: const Text('利用規約'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () =>
                  launchUrl(_termsUrl, mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      );
}
