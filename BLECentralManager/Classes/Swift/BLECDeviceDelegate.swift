//
//  BLECDeviceDelegate.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/5/16.
//
//

import Foundation
import CoreBluetooth

public protocol BLECDeviceDelegate: class {

    func deviceForCharacteristic(_ charasteristic: CBCharacteristic, ofPeripheral peripheral: CBPeripheral) -> BLECCharacteristicDelegate?

    func centralDidUpdateState(_ manager: BLECManager)
    func central(_ manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int)
    func central(_ manager: BLECManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: Error?)
    func central(_ central: BLECManager, didConnectPeripheral peripheral: CBPeripheral)
    func central(_ central: BLECManager, didDisconnectDevice device: BLECDevice, error: Error?)
    func central(_ central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice)

    func device(_ device: BLECDevice, didReadRSSI RSSI: Int, error: Error?)
    func deviceDidUpdateName(_ device: BLECDevice)

}

public extension BLECDeviceDelegate {
    func deviceForCharacteristic(_ charasteristic: CBCharacteristic, ofPeripheral peripheral: CBPeripheral) -> BLECCharacteristicDelegate? { return nil }

    func centralDidUpdateState(_ manager: BLECManager) {}
    func central(_ manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {}
    func central(_ manager: BLECManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: Error?) {}
    func central(_ central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {}
    func central(_ central: BLECManager, didDisconnectDevice device: BLECDevice, error: Error?) {}
    func central(_ central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {}

    func device(_ device: BLECDevice, didReadRSSI RSSI: Int, error: Error?) {}
    func deviceDidUpdateName(_ device: BLECDevice) {}
}
