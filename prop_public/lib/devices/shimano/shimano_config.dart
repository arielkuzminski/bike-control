//INFO: This is a stub - contact me if you need the full implementation.
//
// The full implementation authenticates against the Di2 config service and
// decodes its button-mode paddle telemetry. All bodies here are stubbed and
// every UUID / passkey below is a FAKE placeholder.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;

/// BLE seam for the Shimano protocol code. The app supplies a `universal_ble`
/// backed implementation; tests supply a fake.
abstract class ShimanoTransport {
  Future<void> subscribe(String characteristic);
  Future<void> write(String characteristic, Uint8List data, {bool withoutResponse = false});
  Future<Uint8List> read(String characteristic);

  /// Notifications delivered on [characteristic] after [subscribe].
  Stream<Uint8List> notifications(String characteristic);
}

/// Characteristics of the Di2 config service. FAKE placeholder UUIDs.
class ShimanoDi2Config {
  ShimanoDi2Config._();

  static const String authControlChar = '00000000-0000-0000-0000-0000000000e0';
  static const String pceResponseChar = '00000000-0000-0000-0000-0000000000e1';
  static const String pceAuxNotify1 = '00000000-0000-0000-0000-0000000000e2';
  static const String pceAuxNotify2 = '00000000-0000-0000-0000-0000000000e3';
}

class ShimanoAuth {
  ShimanoAuth._();

  /// FAKE placeholder: the real default passkey lives in the full package.
  static const String defaultPasskey = '00000000';
}

/// The authentication handshake failed.
class ShimanoAuthException implements Exception {
  ShimanoAuthException(this.message);
  final String message;
  @override
  String toString() => 'ShimanoAuthException: $message';
}

/// The Di2 refused the passkey. A kind of [ShimanoAuthException]: the app
/// catches the latter and then tells the two apart.
class ShimanoPasskeyRejectedException extends ShimanoAuthException {
  ShimanoPasskeyRejectedException([this.status]) : super('passkey rejected');

  /// The status byte the Di2 answered with, when known.
  final int? status;

  @override
  String toString() =>
      'ShimanoPasskeyRejectedException: $message${status == null ? '' : ' (0x${status!.toRadixString(16).padLeft(2, '0')})'}';
}

/// Helpers for PC-connect (PCE) frames.
class ShimanoPce {
  ShimanoPce._();

  /// The bytes of [hex], e.g. `'3341'`; whitespace is ignored.
  static Uint8List fromHex(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s'), '');
    if (clean.length.isOdd) throw FormatException('Odd number of hex digits', hex);
    return Uint8List.fromList([
      for (var i = 0; i < clean.length; i += 2) int.parse(clean.substring(i, i + 2), radix: 16),
    ]);
  }
}

/// A shifter turned down a switch-setting write: it keeps its old setting.
class ShimanoSwitchWriteRejectedException implements Exception {
  ShimanoSwitchWriteRejectedException([this.message = 'switch setting rejected']);
  final String message;
  @override
  String toString() => 'ShimanoSwitchWriteRejectedException: $message';
}

enum ShimanoShifter { left, right }

enum ShimanoPaddle { big, small, hood, satellite }

enum ShimanoPaddleState { down, released, held }

class ShimanoPaddleEvent {
  const ShimanoPaddleEvent(this.shifter, this.paddle, this.state);
  final ShimanoShifter shifter;
  final ShimanoPaddle paddle;
  final ShimanoPaddleState state;
}

/// Decodes the paddle presses a button-mode frame carries.
class ShimanoButtons {
  ShimanoButtons._();

  /// Stubbed: the frame layout lives in the full package, so this finds none.
  static List<ShimanoPaddleEvent> decode(Uint8List frame) => const [];
}

/// A press on a switch of a wired lever. Wired levers report which input
/// (junction port) and switch number fired, not which shifter or paddle.
class ShimanoWiredSwitchEvent {
  const ShimanoWiredSwitchEvent(this.input, this.switchNo, this.state);

  final int input;
  final int switchNo;
  final ShimanoPaddleState state;

  /// Stubbed: the full implementation decodes the wired-switch frame; this
  /// recognises none.
  static ShimanoWiredSwitchEvent? decode(Uint8List frame) => null;

  @override
  bool operator ==(Object other) =>
      other is ShimanoWiredSwitchEvent && other.input == input && other.switchNo == switchNo && other.state == state;

  @override
  int get hashCode => Object.hash(input, switchNo, state);

  @override
  String toString() => 'ShimanoWiredSwitchEvent(input $input, switch $switchNo, ${state.name})';
}

/// What one shifter's switches do, as the shifter reports it when pressed in
/// PC-connect mode. [slot] is 0 for the left shifter, 1 for the right.
///
/// The app keeps it as a backup (JSON) to put the original setting back, and
/// writes it with [ShimanoConfig.writeSwitches]. [raw] is the setting in the
/// shifter's own encoding, which only the full implementation reads.
class ShimanoShifterSwitches {
  const ShimanoShifterSwitches({required this.slot, required this.raw, this.paddlesOnDfly = false});

  final int slot;
  final List<int> raw;

  /// Whether both paddles already send D-Fly channels instead of shifting.
  final bool paddlesOnDfly;

  /// Stubbed: the telemetry layout lives in the full package, so no frame is
  /// recognised as a shifter's switch report.
  static ShimanoShifterSwitches? fromTelemetry(Uint8List frame) => null;

  /// This shifter with its paddles moved onto D-Fly channels. Stubbed: only
  /// marks it; the full implementation rewrites [raw].
  ShimanoShifterSwitches withDflyPaddles() => ShimanoShifterSwitches(slot: slot, raw: raw, paddlesOnDfly: true);

  Map<String, dynamic> toJson() => {'slot': slot, 'raw': raw, 'dfly': paddlesOnDfly};

  /// Null for an entry that isn't a valid backup.
  static ShimanoShifterSwitches? fromJson(Map<String, dynamic> json) {
    final slot = json['slot'];
    final raw = json['raw'];
    if (slot is! int || raw is! List) return null;
    return ShimanoShifterSwitches(
      slot: slot,
      raw: [for (final b in raw) if (b is int) b],
      paddlesOnDfly: json['dfly'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShimanoShifterSwitches &&
      other.slot == slot &&
      other.paddlesOnDfly == paddlesOnDfly &&
      listEquals(other.raw, raw);

  @override
  int get hashCode => Object.hash(slot, paddlesOnDfly, Object.hashAll(raw));

  @override
  String toString() => 'ShimanoShifterSwitches(${slot == 0 ? 'left' : 'right'}${paddlesOnDfly ? ', D-Fly' : ''})';
}

/// A running button-mode session; closing it lets the Di2 shift by itself.
class ShimanoButtonSession {
  const ShimanoButtonSession();

  Future<void> close() async {}
}

class ShimanoConfig {
  ShimanoConfig._();

  /// How long [writeSwitches] waits after the shifter stops answering before
  /// it takes the write as saved.
  static const Duration switchWriteQuiet = Duration(milliseconds: 500);

  /// Stubbed: the full implementation runs the Di2 authentication handshake.
  static Future<void> authenticate(ShimanoTransport transport, {required String passkey}) =>
      throw UnimplementedError();

  /// Stubbed: the full implementation replays the button-mode sequence and
  /// reports paddle presses through [onPaddle], and wired-lever presses
  /// through [onWiredSwitch].
  static Future<ShimanoButtonSession> enterButtonMode(
    ShimanoTransport transport, {
    required void Function(ShimanoPaddleEvent event) onPaddle,
    void Function(ShimanoWiredSwitchEvent event)? onWiredSwitch,
    required void Function(Uint8List frame) onUnknownFrame,
    required void Function(String step, Object error, StackTrace stackTrace) onStepError,
  }) => throw UnimplementedError();

  /// Stubbed: the full implementation writes [switches] to its shifter, calls
  /// [onWrite] with each command sent, and completes once the shifter saved
  /// it, or throws [ShimanoSwitchWriteRejectedException] when it is turned
  /// down within [rejectGrace].
  static Future<void> writeSwitches(
    ShimanoTransport transport,
    ShimanoShifterSwitches switches, {
    Duration quiet = switchWriteQuiet,
    Duration rejectGrace = const Duration(seconds: 3),
    void Function(List<int> command)? onWrite,
  }) => throw UnimplementedError();
}
