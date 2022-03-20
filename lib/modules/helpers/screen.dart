import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';
import 'package:window_manager/window_manager.dart';
import '../app/state.dart';
import '../state/eventer.dart';

class ScreenState {
  ScreenState({
    required final this.maximized,
    required final this.bounds,
  });

  final bool maximized;
  final Rect bounds;
}

class FullscreenPreserver {
  FullscreenPreserver([this.checkInterval = const Duration(seconds: 5)]);

  final Duration checkInterval;
  final ValueNotifier<bool> isFullscreened =
      ValueNotifier<bool>(Screen.isFullscreened);

  ScreenState? prevScreenState;
  OnFullscreenChange? fullscreenWatcher;

  Future<void> enterFullscreen() async {
    prevScreenState = await Screen.enterFullscreen();
    fullscreenWatcher = OnFullscreenChange(checkInterval);
    isFullscreened.value = true;
  }

  Future<void> exitFullscreen() async {
    fullscreenWatcher?.dispose();

    if (isFullscreened.value) {
      await Screen.exitFullscreen(prevScreenState);
    }

    isFullscreened.value = false;
  }
}

mixin FullscreenMixin {
  late Duration fullscreenInterval;
  ScreenState? prevScreenState;
  OnFullscreenChange? fullscreenWatcher;
  final ValueNotifier<bool> isFullscreened =
      ValueNotifier<bool>(Screen.isFullscreened);

  // ignore: use_setters_to_change_properties
  void initFullscreen([final Duration interval = const Duration(seconds: 5)]) {
    fullscreenInterval = interval;
  }

  Future<void> enterFullscreen() async {
    prevScreenState = await Screen.enterFullscreen();
    fullscreenWatcher = OnFullscreenChange(fullscreenInterval);
    isFullscreened.value = true;
  }

  Future<void> exitFullscreen() async {
    fullscreenWatcher?.dispose();

    if (isFullscreened.value) {
      await Screen.exitFullscreen(prevScreenState);
    }

    isFullscreened.value = false;
  }
}

mixin OrientationMixin {
  Future<void> enterLandscape() =>
      Screen.setOrientation(ScreenOrientation.vertical);

  Future<void> exitLandscape() =>
      Screen.setOrientation(ScreenOrientation.unlock);
}

mixin WakelockMixin {
  Future<bool> isWakelockEnabled() => Screen.isWakelockEnabled();

  Future<void> enableWakelock() => Screen.enableWakelock();

  Future<void> disableWakelock() => Screen.disableWakelock();
}

class OnFullscreenChange {
  OnFullscreenChange(this.duration, [this.onChange]) {
    Screen.uiChangeNotifier.subscribe(onUiChange);
  }

  final void Function()? onChange;
  final Duration duration;

  Timer? timer;

  void dispose() {
    timer?.cancel();
    timer = null;
    Screen.uiChangeNotifier.unsubscribe(onUiChange);
  }

  // ignore: avoid_positional_boolean_parameters
  void onUiChange(final bool fullscreen) {
    timer?.cancel();
    timer = null;
    if (!fullscreen) {
      timer = Timer(duration, () async {
        if (!Screen.isFullscreened) {
          await Screen.enterFullscreen();
        }
      });
      onChange?.call();
    }
  }
}

enum ScreenOrientation {
  unlock,
  vertical,
}

abstract class Screen {
  static final Eventer<bool> uiChangeNotifier = Eventer<bool>();

  static bool isFullscreened = false;

  static Future<void> initialize() async {
    if (AppState.isMobile) {
      SystemChrome.setSystemUIChangeCallback((final bool fullscreen) async {
        isFullscreened = fullscreen;

        uiChangeNotifier.dispatch(fullscreen);
      });
    }
  }

  static Future<void> setTitle(final String title) async {
    if (!AppState.isDesktop) return;

    await WindowManager.instance.setTitle(title);
  }

  static Future<void> close() async {
    if (!AppState.isDesktop) return;

    await WindowManager.instance.close();
  }

  static Future<void> focus() async {
    if (!AppState.isDesktop) return;

    await WindowManager.instance.show();
    await WindowManager.instance.focus();
  }

  static Future<ScreenState?> enterFullscreen() async {
    ScreenState? state;

    if (AppState.isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      state = ScreenState(
        bounds: await WindowManager.instance.getBounds(),
        maximized: await WindowManager.instance.isMaximized(),
      );

      WindowManager.instance.setFullScreen(true);
    }

    isFullscreened = true;
    return state;
  }

  static Future<void> exitFullscreen([final ScreenState? state]) async {
    if (AppState.isMobile) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } else {
      WindowManager.instance.setFullScreen(false);

      if (state != null) {
        await WindowManager.instance.setBounds(state.bounds);
        if (state.maximized) {
          WindowManager.instance.maximize();
        }
      }
    }

    isFullscreened = false;
  }

  static Future<void> setOrientation(
    final ScreenOrientation orientation,
  ) async {
    if (AppState.isMobile) {
      final List<DeviceOrientation> to;
      switch (orientation) {
        case ScreenOrientation.vertical:
          to = <DeviceOrientation>[
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ];
          break;

        default:
          to = <DeviceOrientation>[];
      }

      await SystemChrome.setPreferredOrientations(to);
    }
  }

  static Future<bool> isWakelockEnabled() async =>
      !Platform.isLinux && await Wakelock.enabled;

  static Future<void> enableWakelock() async {
    if (!Platform.isLinux) {
      await Wakelock.enable();
    }
  }

  static Future<void> disableWakelock() async {
    if (!Platform.isLinux) {
      await Wakelock.disable();
    }
  }
}
