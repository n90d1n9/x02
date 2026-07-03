import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_office/ky_office.dart';

import 'worksuite_workspace.dart';

void main() {
  runApp(const ProviderScope(child: WorksuiteApp()));
}

class WorksuiteApp extends StatelessWidget {
  const WorksuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaysir Office',
      theme: KyOfficeTheme.light(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const WorksuiteWorkspace(),
    );
  }
}
