class Book {
  final String id, title, author, description, category, coverUrl, downloadUrl;
  final bool isMagazine;
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.downloadUrl,
    this.isMagazine = false,
  });
}
