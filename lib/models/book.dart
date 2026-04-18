class Book {
  String id;
  String title;
  String author;
  String categoryId;
  String epubUrl; // Đã đổi tên
  String imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.epubUrl,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'categoryId': categoryId,
      'epubUrl': epubUrl,
      'imageUrl': imageUrl,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      categoryId: map['categoryId'] ?? '',
      epubUrl: map['epubUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}