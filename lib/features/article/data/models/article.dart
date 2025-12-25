import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'article.g.dart';

@JsonSerializable()
@collection
class Article {
  final Id id;

  final String title;

  final String content;

  @Index(unique: true)
  final String url;

  final String source;

  final DateTime publishedAt;

  final bool isStar;

  final bool isRead;

  final String? summary;

  final String? noteExternalId;

  const Article({
    required this.id,
    required this.title,
    required this.content,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.isStar = false,
    this.isRead = false,
    this.summary,
    this.noteExternalId,
  });

  factory Article.fromJson(Map<String, dynamic> json) => _$ArticleFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleToJson(this);

  Article copyWith({
    Id? id,
    String? title,
    String? content,
    String? url,
    String? source,
    DateTime? publishedAt,
    bool? isStar,
    bool? isRead,
    String? summary,
    String? noteExternalId,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      isStar: isStar ?? this.isStar,
      isRead: isRead ?? this.isRead,
      summary: summary ?? this.summary,
      noteExternalId: noteExternalId ?? this.noteExternalId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url;

  @override
  int get hashCode => id.hashCode ^ url.hashCode;

  @override
  String toString() {
    return 'Article{id: $id, title: $title, url: $url, source: $source, publishedAt: $publishedAt}';
  }
}