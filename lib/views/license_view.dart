import 'package:flutter/material.dart';

class LicenseView extends StatelessWidget {
  const LicenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensePage(
      applicationName: '', // アプリの名前
      // applicationVersion: '1.0.0', // バージョン
      // applicationIcon: Icon(Icons.car_repair), // アプリのアイコン
      // applicationLegalese: 'All rights reserved', // 著作権表示
    );
  }
}
