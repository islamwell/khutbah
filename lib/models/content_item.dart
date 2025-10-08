enum ContentType { quran, hadith, quote }

enum AuthenticityLevel { sahih, hasan, daif, unknown }

class ContentItem {
  final String id;
  final String text;
  final String translation;
  final String source;
  final ContentType type;
  final AuthenticityLevel? authenticity;
  final String? surahName;
  final int? verseNumber;
  final List<String> keywords;

  const ContentItem({
    required this.id,
    required this.text,
    required this.translation,
    required this.source,
    required this.type,
    this.authenticity,
    this.surahName,
    this.verseNumber,
    required this.keywords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'translation': translation,
        'source': source,
        'type': type.name,
        'authenticity': authenticity?.name,
        'surahName': surahName,
        'verseNumber': verseNumber,
        'keywords': keywords.join(','),
      };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String,
        text: json['text'] as String,
        translation: json['translation'] as String,
        source: json['source'] as String,
        type: ContentType.values.firstWhere((e) => e.name == json['type']),
        authenticity: json['authenticity'] != null
            ? AuthenticityLevel.values.firstWhere((e) => e.name == json['authenticity'])
            : null,
        surahName: json['surahName'] as String?,
        verseNumber: json['verseNumber'] as int?,
        keywords: (json['keywords'] as String? ?? '').isEmpty
            ? <String>[]
            : (json['keywords'] as String).split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList(),
      );

  String get displaySource {
    switch (type) {
      case ContentType.quran:
        return surahName != null && verseNumber != null 
            ? '$surahName $verseNumber' 
            : source;
      case ContentType.hadith:
        final auth = authenticity != null ? ' (${authenticity!.name.toUpperCase()})' : '';
        return '$source$auth';
      case ContentType.quote:
        return source;
    }
  }
}