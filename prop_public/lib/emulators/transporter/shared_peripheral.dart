// The phone has one BLE peripheral, and universal_ble exposes a single global
// read handler and a single global write handler for it. Every role that
// serves from that peripheral (the app's PeripheralServer instances, the
// OpenBikeControl service, the trainer bridge) registers here instead, and the
// one router installed below dispatches each request by characteristic UUID.
//
// Reconstructed from the app's use of it: the router is the one this fork's
// PeripheralServer carried before upstream moved it into this package.

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

class SharedPeripheral {
  SharedPeripheral._();

  static bool _routerInstalled = false;
  static final Map<String, OnPeripheralReadRequest> _readHandlers = {};
  static final Map<String, OnPeripheralWriteRequest> _writeHandlers = {};
  static final Set<String> _protected = {};

  static void _installRouter() {
    if (_routerInstalled) return;
    _routerInstalled = true;
    UniversalBlePeripheral.setReadRequestHandlers((deviceId, characteristicId, offset, value) {
      return _readHandlers[characteristicId.toLowerCase()]?.call(deviceId, characteristicId, offset, value);
    });
    UniversalBlePeripheral.setWriteRequestHandlers((deviceId, characteristicId, offset, value) {
      return _writeHandlers[characteristicId.toLowerCase()]?.call(deviceId, characteristicId, offset, value);
    });
  }

  static void setReadHandler(String characteristicId, OnPeripheralReadRequest handler) {
    _installRouter();
    _readHandlers[characteristicId.toLowerCase()] = handler;
  }

  static void setWriteHandler(String characteristicId, OnPeripheralWriteRequest handler) {
    _installRouter();
    _writeHandlers[characteristicId.toLowerCase()] = handler;
  }

  /// Removes the read handler for [characteristicId], but only while it is
  /// still [handler]: another role may have registered the same UUID since.
  static void removeReadHandler(String characteristicId, OnPeripheralReadRequest handler) {
    final key = characteristicId.toLowerCase();
    if (identical(_readHandlers[key], handler)) _readHandlers.remove(key);
  }

  /// Like [removeReadHandler], for writes.
  static void removeWriteHandler(String characteristicId, OnPeripheralWriteRequest handler) {
    final key = characteristicId.toLowerCase();
    if (identical(_writeHandlers[key], handler)) _writeHandlers.remove(key);
  }

  /// Marks [serviceUuids] as owned by a role that must outlive the trainer
  /// bridge: a bridge starting or stopping must not remove them.
  static void protectServices(Iterable<String> serviceUuids) => _protected.addAll(serviceUuids.map((s) => s.toLowerCase()));

  static void unprotectServices(Iterable<String> serviceUuids) =>
      _protected.removeAll(serviceUuids.map((s) => s.toLowerCase()));

  /// Whether [serviceUuid] was protected with [protectServices].
  static bool isProtected(String serviceUuid) => _protected.contains(serviceUuid.toLowerCase());

  @visibleForTesting
  static void debugReset() {
    _routerInstalled = false;
    _readHandlers.clear();
    _writeHandlers.clear();
    _protected.clear();
  }
}
