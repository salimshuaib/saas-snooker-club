import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/features/settings/domain/models/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('test update state', () async {
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'test',
      version: '1.0.4',
      buildNumber: '1',
      buildSignature: '',
    );
    final container = ProviderContainer(
      overrides: [
        appVersionConfigProvider.overrideWith((ref) => Stream.value(
          AppVersionConfig(
            minimumRequiredVersion: '1.0.5',
            latestVersion: '1.0.5',
            forceUpdate: true,
            updateUrl: 'test',
            updateMessage: 'test',
          )
        )),
      ]
    );
    
    // Wait for async providers to load
    await container.read(packageInfoProvider.future);
    
    // Listen to force the stream to execute
    final sub = container.listen(updateStateProvider, (_, __) {});
    
    await Future.delayed(Duration(milliseconds: 200));
    
    final state = container.read(updateStateProvider);
    print('isForceUpdateRequired: ${state.isForceUpdateRequired}');
    print('currentVersion: ${state.currentVersion}');
    print('latestVersion: ${state.latestVersion}');
  });
}
