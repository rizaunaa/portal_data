class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.itemName,
    required this.itemCode,
    required this.category,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.itemCondition,
    required this.location,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String photoUrl;
  final String itemName;
  final String itemCode;
  final String category;
  final String brand;
  final int quantity;
  final String unit;
  final String itemCondition;
  final String location;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'photo_url': photoUrl,
      'item_name': itemName,
      'item_code': itemCode,
      'category': category,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'item_condition': itemCondition,
      'location': location,
      'notes': notes,
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

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    int parseQuantity(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse('$value') ?? 0;
    }

    return InventoryItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      photoUrl: map['photo_url'] as String? ?? '',
      itemName: map['item_name'] as String? ?? '',
      itemCode: map['item_code'] as String? ?? '',
      category: map['category'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      quantity: parseQuantity(map['quantity']),
      unit: map['unit'] as String? ?? 'unit',
      itemCondition: map['item_condition'] as String? ?? 'baik',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
