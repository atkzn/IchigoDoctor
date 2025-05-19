//
/*
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
*/

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static final _privacyUrl = Uri.parse(
      'https://dadand-kikai.github.io/IchigoDoctor/privacy_policy');
  static final _termsUrl = Uri.parse(
      'https://dadand-kikai.github.io/IchigoDoctor/terms_of_service');

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 確認ダイアログ
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退会確認'),
        content: const Text('アカウントと関連データを完全に削除します。よろしいですか?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final password = await _askPasswordDialog();
        if (password == null) return;
        final cred = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(cred);
        await user.delete();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: ${e.message}')),
          );
        }
        return;
      }
    }

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<String?> _askPasswordDialog() async {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('パスワード再入力'),
        content: TextField(
          controller: ctl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, ctl.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(_privacyUrl, mode: LaunchMode.externalApplication),
          ),
          ListTile(
            title: const Text('利用規約'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(_termsUrl, mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          ListTile(
            title: const Text('退会してすべてのデータを削除する'),
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            textColor: Colors.red,
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}