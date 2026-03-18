class Employee {
  const Employee({
    required this.id,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.nip,
    required this.position,
    required this.department,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String photoUrl;
  final String nip;
  final String position;
  final String department;
  final String email;
  final String phone;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'photo_url': photoUrl,
      'nip': nip,
      'position': position,
      'department': department,
      'email': email,
      'phone': phone,
      'address': address,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      ...toInsertMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      photoUrl: map['photo_url'] as String? ?? '',
      nip: map['nip'] as String,
      position: map['position'] as String,
      department: map['department'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
