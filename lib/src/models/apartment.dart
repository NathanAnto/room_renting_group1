class Apartment {
  final String id;
  final String title;
  final String city;
  final int price;
  final String? description;
  final String? ownerId; // pour sécuriser ensuite

  Apartment({
    required this.id,
    required this.title,
    required this.city,
    required this.price,
    this.description,
    this.ownerId,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'city': city,
        'price': price,
        'description': description,
        'ownerId': ownerId,
      };

  factory Apartment.fromMap(String id, Map<String, dynamic> data) {
    return Apartment(
      id: id,
      title: data['title'] ?? '',
      city: data['city'] ?? '',
      price: (data['price'] ?? 0) as int,
      description: data['description'],
      ownerId: data['ownerId'],
    );
  }
}
