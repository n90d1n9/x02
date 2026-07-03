import 'dart:async';

import '../models/spell_check_error.dart';
import '../models/spell_check_service.dart';

typedef SpellCheckTextReader = String Function();
typedef SpellCheckErrorWriter = void Function(List<SpellCheckError> errors);

class DocumentSpellCheckController {
  static const defaultInterval = Duration(seconds: 2);

  final SpellCheckService _spellCheck;
  final Duration interval;

  Timer? _timer;

  DocumentSpellCheckController(
    this._spellCheck, {
    this.interval = defaultInterval,
  });

  void start({
    required SpellCheckTextReader readText,
    required SpellCheckErrorWriter onErrors,
  }) {
    stop();
    _timer = Timer.periodic(interval, (_) {
      run(readText: readText, onErrors: onErrors);
    });
    run(readText: readText, onErrors: onErrors);
  }

  void stop({SpellCheckErrorWriter? onErrors}) {
    _timer?.cancel();
    _timer = null;
    onErrors?.call(const []);
  }

  void run({
    required SpellCheckTextReader readText,
    required SpellCheckErrorWriter onErrors,
  }) {
    onErrors(_spellCheck.checkText(readText()));
  }

  void addToDictionary(String word) {
    _spellCheck.addToDictionary(word);
  }

  void ignoreWord(String word) {
    _spellCheck.ignoreWord(word);
  }

  void dispose() {
    stop();
  }
}
