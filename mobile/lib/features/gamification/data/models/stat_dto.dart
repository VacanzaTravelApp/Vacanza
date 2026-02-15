/// A single stat entry from the gamification profile.
///
/// Example JSON: `{ "label": "Places", "value": 12 }`
class StatDto {
  final String label;
  final int value;

  const StatDto({
    required this.label,
    required this.value,
  });

  factory StatDto.fromJson(Map<String, dynamic> json) {
    return StatDto(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'StatDto(label: $label, value: $value)';
}
