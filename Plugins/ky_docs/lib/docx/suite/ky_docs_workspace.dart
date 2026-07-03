import 'package:flutter/material.dart';

import '../../docx/screens/document_editor_page.dart';
import '../../docx/screens/document_list_page.dart';
import '../screens/document_editor_screen.dart';
import 'ky_docs_surface.dart';
import 'widgets/ky_docs_home.dart';
import 'widgets/ky_docs_sidebar.dart';

class KyDocsWorkspace extends StatefulWidget {
  final KyDocsSurface initialSurface;

  const KyDocsWorkspace({super.key, this.initialSurface = KyDocsSurface.home});

  @override
  State<KyDocsWorkspace> createState() => _KyDocsWorkspaceState();
}

class _KyDocsWorkspaceState extends State<KyDocsWorkspace> {
  late KyDocsSurface _surface;

  @override
  void initState() {
    super.initState();
    _surface = widget.initialSurface;
  }

  void _openSurface(KyDocsSurface surface) {
    setState(() => _surface = surface);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          body: Row(
            children: [
              if (!compact)
                KyDocsSidebar(
                  selectedSurface: _surface,
                  onSurfaceSelected: _openSurface,
                ),
              Expanded(child: _buildSurface()),
            ],
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: KyDocsSurfaceCatalog.primary.indexOf(_surface),
                  onDestinationSelected: (index) {
                    _openSurface(KyDocsSurfaceCatalog.primary[index]);
                  },
                  destinations: KyDocsSurfaceCatalog.primary.map((surface) {
                    return NavigationDestination(
                      icon: Icon(surface.icon),
                      label: surface.label,
                    );
                  }).toList(),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSurface() {
    return switch (_surface) {
      KyDocsSurface.home => KyDocsHome(onOpenSurface: _openSurface),
      KyDocsSurface.library => DocumentListPage(
        onOpenEditor: () => _openSurface(KyDocsSurface.wordEditor),
      ),
      KyDocsSurface.wordEditor => const DocumentEditorPage(),
      KyDocsSurface.liveDocs => const DocumentEditorScreen(),
    };
  }
}
