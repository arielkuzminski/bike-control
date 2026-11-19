//INFO: This is a stub - contact me if you need the full implementation.

import 'package:flutter/foundation.dart';
import 'package:prop/emulators/definitions/proxy_bike_definition.dart';
import 'package:prop/utils/constants.dart';
import 'package:universal_ble/universal_ble.dart';

class ZwiftEmulatorDefinition extends ProxyBikeDefinition {
  ZwiftEmulatorDefinition({
    required super.device,
    bool Function()? asRide,
  }) : asRide = asRide ?? _never,
       super(
         data: ValueNotifier(''),
         services: [
           BleService(
             FtmsMdnsConstants.ZWIFT_RIDE_CUSTOM_SERVICE_UUID,
             [
               BleCharacteristic(FtmsMdnsConstants.ZWIFT_SYNC_RX_CHARACTERISTIC_UUID, [CharacteristicProperty.write], []),
               BleCharacteristic(FtmsMdnsConstants.ZWIFT_ASYNC_CHARACTERISTIC_UUID, [CharacteristicProperty.notify], []),
               BleCharacteristic(FtmsMdnsConstants.ZWIFT_SYNC_TX_CHARACTERISTIC_UUID, [CharacteristicProperty.notify], []),
             ],
           ),
         ],
       );

  static bool _never() => false;

  /// Asked on each handshake whether to answer as a Zwift Ride rather than a
  /// Click. A callback because the trainer app can change while the emulator
  /// runs. Stubbed: the stub answers no handshake, so it is never read here.
  final bool Function() asRide;

  @override
  List<String> get serviceUUIDs => [FtmsMdnsConstants.ZWIFT_RIDE_CUSTOM_SERVICE_UUID];

  @override
  List<String> get advertiseServiceUUIDs => const [];

  @override
  void onWriteRequest(String characteristicUUID, List<int> characteristicData) {}
}
