import 'lib/features/settings/domain/models/app_config.dart';

void main() {
  final map = {
    'minimum_required_version': '1.0.4',
    'latest_version': '1.0.4',
    'force_update': true,
    'update_message':
        'A critical update is required. Please download the latest version to continue using the app.',
  };
  final config = AppVersionConfig.fromMap(map);
  print(config.minimumRequiredVersion);
  print(config.forceUpdate);
}
