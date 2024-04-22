class Company {
  final String name;

  Company({
    required this.name,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
    );
  }
}

class Category {
  final int id;
  final String nameEn;
  final String nameBn;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameBn,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameEn: json['name_en'],
      nameBn: json['name_bn'],
    );
  }
}