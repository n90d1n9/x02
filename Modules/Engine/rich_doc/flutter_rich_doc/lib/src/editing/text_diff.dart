/// Turns a `TextEditingController`'s before/after text into the
/// minimal `insert_text`/`delete_text` op pair needed to reproduce the
/// change in Rust. A longest-common-prefix/suffix diff is sufficient
/// here (not a full Myers diff) because Flutter already hands us
/// exactly one edit's worth of before/after per listener callback.
library rich_doc_text_diff;

class TextEdit {
  final int start;
  final int deleteCount;
  final String insert;
  const TextEdit({required this.start, required this.deleteCount, required this.insert});
}

TextEdit? diffText(String oldText, String newText) {
  if (oldText == newText) return null;

  var prefix = 0;
  final maxPrefix = oldText.length < newText.length ? oldText.length : newText.length;
  while (prefix < maxPrefix && oldText[prefix] == newText[prefix]) {
    prefix++;
  }

  var oldEnd = oldText.length;
  var newEnd = newText.length;
  while (oldEnd > prefix && newEnd > prefix && oldText[oldEnd - 1] == newText[newEnd - 1]) {
    oldEnd--;
    newEnd--;
  }

  return TextEdit(start: prefix, deleteCount: oldEnd - prefix, insert: newText.substring(prefix, newEnd));
}
