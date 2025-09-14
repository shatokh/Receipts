class Merchant {
  final String id;
  final String name;
  final String? nip;
  final String? address;
  final String? city;

  const Merchant({
    required this.id,
    required this.name,
    this.nip,
    this.address,
    this.city,
  });

  Merchant copyWith({
    String? id,
    String? name,
    String? nip,
    String? address,
    String? city,
  }) => Merchant(
    id: id ?? this.id,
    name: name ?? this.name,
    nip: nip ?? this.nip,
    address: address ?? this.address,
    city: city ?? this.city,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nip': nip,
    'address': address,
    'city': city,
  };

  factory Merchant.fromMap(Map<String, dynamic> map) => Merchant(
    id: map['id'],
    name: map['name'],
    nip: map['nip'],
    address: map['address'],
    city: map['city'],
  );
}