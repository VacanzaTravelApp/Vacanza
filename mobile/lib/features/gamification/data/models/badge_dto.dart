/// A single badge entry from the gamification profile.
///
/// Example JSON: `{ "id": 1, "title": "First Step", "key": "speed", "earned": true }`
///
/// [key] is used for icon mapping in MOB-11.
class BadgeDto {
  final int id;
  final String title;
  final String key;
  final bool earned;

  const BadgeDto({
    required this.id,
    required this.title,
    required this.key,
    required this.earned,
  });

  factory BadgeDto.fromJson(Map<String, dynamic> json) {
    return BadgeDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      earned: json['earned'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'BadgeDto(id: $id, title: $title, key: $key, earned: $earned)';
}
