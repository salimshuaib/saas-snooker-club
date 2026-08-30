class AppVersionConfig {
  final String minimumRequiredVersion;
  final String latestVersion;
  final String updateUrl;
  final bool forceUpdate;
  final String updateMessage;

  const AppVersionConfig({
    required this.minimumRequiredVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.forceUpdate,
    required this.updateMessage,
  });

  factory AppVersionConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AppVersionConfig(
        minimumRequiredVersion: '1.0.0',
        latestVersion: '1.0.0',
        updateUrl: '',
        forceUpdate: false,
        updateMessage: 'A new version of Sharma Billiards is available.',
      );
    }
    return AppVersionConfig(
      minimumRequiredVersion: map['minimum_required_version'] as String? ?? '1.0.0',
      latestVersion: map['latest_version'] as String? ?? '1.0.0',
      updateUrl: map['update_url'] as String? ?? '',
      forceUpdate: map['force_update'] as bool? ?? false,
      updateMessage: map['update_message'] as String? ?? 'A new version of Sharma Billiards is available.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minimum_required_version': minimumRequiredVersion,
      'latest_version': latestVersion,
      'update_url': updateUrl,
      'force_update': forceUpdate,
      'update_message': updateMessage,
    };
  }
}
