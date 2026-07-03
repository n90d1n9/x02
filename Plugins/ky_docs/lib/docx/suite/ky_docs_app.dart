import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ky_docs_surface.dart';
import 'ky_docs_theme.dart';
import 'ky_docs_workspace.dart';

class KyDocsApp extends StatelessWidget {
  final KyDocsSurface initialSurface;
  final ThemeMode themeMode;
  final String title;

  const KyDocsApp({
    super.key,
    this.initialSurface = KyDocsSurface.home,
    this.themeMode = ThemeMode.system,
    this.title = 'Kaysir Docs',
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        theme: KyDocsTheme.light(),
        darkTheme: KyDocsTheme.dark(),
        themeMode: themeMode,
        home: KyDocsWorkspace(initialSurface: initialSurface),
      ),
    );
  }
}
