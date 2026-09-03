class MagazineIssue {
  final String id;
  final String magazineId;
  final int issueNumber;
  final String? title;
  final String? description;
  final String? coverUrl;
  final String downloadUrl;

  const MagazineIssue({
    required this.id,
    required this.magazineId,
    required this.issueNumber,
    this.title,
    this.description,
    this.coverUrl,
    required this.downloadUrl,
  });

  factory MagazineIssue.fromMap(
    Map<String, dynamic> map,
  ) {
    return MagazineIssue(
      id: map['id'] as String,
      magazineId: map['magazine_id'] as String,
      issueNumber: map['issue_number'] as int,
      title: map['title'] as String?,
      description: map['description'] as String?,
      coverUrl: map['cover_url'] as String?,
      downloadUrl: map['download_url'] as String,
    );
  }
}
