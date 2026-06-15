// ignore_for_file: deprecated_member_use
import 'dart:js' as js;

class SoundService {
  static bool _muted = false;
  static bool get muted => _muted;

  static void toggleMute() {
    _muted = !_muted;
    _call('sfr_setMuted', [_muted]);
  }

  static void tap()     => _call('sfr_soundTap', []);
  static void advance() => _call('sfr_soundAdvance', []);
  static void success() => _call('sfr_soundSuccess', []);
  static void ripple()  => _call('sfr_soundRipple', []);
  static void whoosh()  => _call('sfr_soundWhoosh', []);
  static void error()   => _call('sfr_soundError', []);
  static void chime()   => _call('sfr_soundChime', []);

  static void _call(String fn, List args) {
    if (_muted) return;
    try {
      js.context.callMethod(fn, args);
    } catch (_) {}
  }
}
