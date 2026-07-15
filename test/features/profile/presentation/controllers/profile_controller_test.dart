import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_state.dart';

void main() {
  test('memuatkan dan mengemas kini profil pengguna', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(profileControllerProvider.notifier);

    await controller.loadProfile();

    var state = container.read(profileControllerProvider);

    expect(state.status, ProfileStatus.success);

    expect(state.profile, isNotNull);

    expect(state.profile!.displayName, 'PelajarPA');

    expect(state.profile!.achievements, hasLength(4));

    expect(state.profile!.topicProgressPercentage, 43);

    final invalidNameError = await controller.updateDisplayName('A');

    expect(invalidNameError, isNotNull);

    final validNameError = await controller.updateDisplayName(
      'Welljoel Walter',
    );

    expect(validNameError, isNull);

    state = container.read(profileControllerProvider);

    expect(state.profile!.displayName, 'Welljoel Walter');

    expect(state.profile!.initials, 'WW');
  });
}
