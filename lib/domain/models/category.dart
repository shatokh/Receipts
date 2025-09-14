class Category {
  final String id;
  final String name;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId ?? this.parentId,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
    parentId: map['parent_id'],
  );
}