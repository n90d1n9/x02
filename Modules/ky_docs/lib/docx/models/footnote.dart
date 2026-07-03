class Footnote {
  final String id;
  final int number;
  final String text;
  final int offset;
  const Footnote({
    required this.id,
    required this.number,
    required this.text,
    required this.offset,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'text': text,
    'offset': offset,
  };
  factory Footnote.fromJson(Map<String, dynamic> json) => Footnote(
    id: json['id'],
    number: json['number'],
    text: json['text'],
    offset: json['offset'],
  );
}
