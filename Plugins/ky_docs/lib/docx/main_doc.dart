import 'package:flutter/material.dart';

import 'suite/ky_docs_app.dart';
import 'suite/ky_docs_surface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KyDocsApp(initialSurface: KyDocsSurface.library));
}
