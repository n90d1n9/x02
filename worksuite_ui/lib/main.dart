import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const WorksuiteWorkspace(),
    );
  }
}
