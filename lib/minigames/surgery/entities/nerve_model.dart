// lib/models/nerve_model.dart

class Nerve {
  Nerve({
    required this.id,
    required this.name,
    required this.description,
    required this.isVital,
    this.isCut = false,
    this.sense = 'unknown',
    this.posX = 0.5,
    this.posY = 0.5,
    this.isTarget = false,
  });

  factory Nerve.fromJson(Map<String, dynamic> json) {
    return Nerve(
      id: json['id'] as String? ?? 'unknown_id',
      name:
          json['titulo'] as String? ??
          json['name'] as String? ??
          'Unknown Nerve',
      description:
          json['descripcion'] as String? ??
          json['description'] as String? ??
          'No data available.',
      isVital: json['isVital'] as bool? ?? false,
      sense:
          json['sentido'] as String? ?? json['sense'] as String? ?? 'unknown',
      posX: (json['posX'] is num) ? (json['posX'] as num).toDouble() : 0.5,
      posY: (json['posY'] is num) ? (json['posY'] as num).toDouble() : 0.5,
    );
  }
  final String id;
  final String name;
  final String description;
  final bool isVital;
  bool isCut;
  String sense;
  double posX; // relative 0..1 within brain image box
  double posY; // relative 0..1 within brain image box
  bool isTarget;
}
