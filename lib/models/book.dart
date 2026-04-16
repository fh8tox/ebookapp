class Book {
  String id;
  String title;
  String author;
  String categoryId;
  String pdfUrl;
  String imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.pdfUrl,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'categoryId': categoryId,
      'pdfUrl': pdfUrl,
      'imageUrl': imageUrl,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      categoryId: map['categoryId'] ?? '',
      pdfUrl: map['pdfUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}