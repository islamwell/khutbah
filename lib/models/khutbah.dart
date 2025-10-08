class Khutbah {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int estimatedMinutes;
  final String? folderId;

  const Khutbah({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.modifiedAt,
    required this.estimatedMinutes,
    this.folderId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags.join(','),
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'folderId': folderId,
      };

  factory Khutbah.fromJson(Map<String, dynamic> json) => Khutbah(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        tags: (json['tags'] as String? ?? '').isEmpty 
            ? <String>[]
            : (json['tags'] as String).split(',').where((tag) => tag.trim().isNotEmpty).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        estimatedMinutes: json['estimatedMinutes'] as int,
        folderId: json['folderId'] as String?,
      );

  Khutbah copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? estimatedMinutes,
    String? folderId,
  }) =>
      Khutbah(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        folderId: folderId ?? this.folderId,
      );
}