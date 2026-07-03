import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_stats.dart';
import 'docs_provider.dart';

final wordCountProvider = Provider<DocumentStats>((ref) {
  final docState = ref.watch(documentControllerProvider);
  return docState.stats;
});
