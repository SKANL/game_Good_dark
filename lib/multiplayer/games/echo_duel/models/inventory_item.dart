class InventoryItem {
  final String objectId;
  final String name;
  int quantity;

  InventoryItem({
    required this.objectId,
    required this.name,
    required this.quantity,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      objectId: json['object_id'] as String,
      name: json['object_name'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
