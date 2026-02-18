class Item {
  const Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
    );
  }
}
