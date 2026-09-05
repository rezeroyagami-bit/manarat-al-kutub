class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String category;
  final String? coverUrl;
  final String downloadUrl;
  final bool isMagazine;
  final bool isExclusive;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.category,
    this.coverUrl,
    required this.downloadUrl,
    this.isMagazine = false,
    this.isExclusive = false,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      coverUrl: map['cover_url'] as String?,
      downloadUrl: map['download_url'] as String,
      isMagazine: map['is_magazine'] as bool? ?? false,
      isExclusive: map['is_exclusive'] as bool? ?? false,
    );
  }
}
