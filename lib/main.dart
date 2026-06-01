import 'package:flutter/material.dart';

void main() {
  runApp(const CashVaultApp());
}

class CashVaultApp extends StatelessWidget {
  const CashVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Cash Vault'),
        ),
      ),
    );
  }
}
