// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accessor for the [SettingsDao], backed by the shared database.

@ProviderFor(settingsDao)
final settingsDaoProvider = SettingsDaoProvider._();

/// Accessor for the [SettingsDao], backed by the shared database.

final class SettingsDaoProvider
    extends $FunctionalProvider<SettingsDao, SettingsDao, SettingsDao>
    with $Provider<SettingsDao> {
  /// Accessor for the [SettingsDao], backed by the shared database.
  SettingsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsDaoHash();

  @$internal
  @override
  $ProviderElement<SettingsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsDao create(Ref ref) {
    return settingsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsDao>(value),
    );
  }
}

String _$settingsDaoHash() => r'a0a5073bee4b1c7ab22a219c1b79798d6aef8421';

/// The app theme mode, resolved from the persisted setting and defaulting to
/// [ThemeMode.system]. Re-emits whenever the stored value changes.

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

/// The app theme mode, resolved from the persisted setting and defaulting to
/// [ThemeMode.system]. Re-emits whenever the stored value changes.

final class ThemeModeProvider
    extends
        $FunctionalProvider<AsyncValue<ThemeMode>, ThemeMode, Stream<ThemeMode>>
    with $FutureModifier<ThemeMode>, $StreamProvider<ThemeMode> {
  /// The app theme mode, resolved from the persisted setting and defaulting to
  /// [ThemeMode.system]. Re-emits whenever the stored value changes.
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $StreamProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ThemeMode> create(Ref ref) {
    return themeMode(ref);
  }
}

String _$themeModeHash() => r'24d9b4f2a99dfb502d3785f31bf0ad0238d4da46';

/// Write commands for app settings.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: caught exceptions become [Err]; programming bugs (`Error`)
/// propagate.

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// Write commands for app settings.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: caught exceptions become [Err]; programming bugs (`Error`)
/// propagate.
final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, void> {
  /// Write commands for app settings.
  ///
  /// Holds no state of its own — the database is the state. Each command returns
  /// a [Result]: caught exceptions become [Err]; programming bugs (`Error`)
  /// propagate.
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'6c2169a4e17d9607d640a5775ac2bc54d4276539';

/// Write commands for app settings.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: caught exceptions become [Err]; programming bugs (`Error`)
/// propagate.

abstract class _$SettingsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
