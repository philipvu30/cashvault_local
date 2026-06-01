class AppSettingModel {
  const AppSettingModel({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  final String key;
  final String value;
  final DateTime updatedAt;
}
