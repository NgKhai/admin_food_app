class News {
  final String newsId;
  final String newsImageUrl;
  final String newsTitle;
  final Function? newsFunction;

  News({
    required this.newsId,
    required this.newsImageUrl,
    required this.newsTitle,
    this.newsFunction,
  });
}