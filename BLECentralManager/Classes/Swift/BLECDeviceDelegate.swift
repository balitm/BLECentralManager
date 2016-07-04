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

    func deviceForCharacteristic(charasteristic: CBCharacteristic, ofPeripheral peripheral: CBPeripheral) -> BLECCharacteristicDelegate?

    func centralDidUpdateState(manager: BLECManager)
    func central(manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int)
    func central(manager: BLECManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
    func central(central: BLECManager, didConnectPeripheral peripheral: CBPeripheral)
    func central(central: BLECManager, didDisconnectDevice device: BLECDevice, error: NSError?)
    func central(central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice)

    func device(device: BLECDevice, didReadRSSI RSSI: Int, error: NSError?)
    func deviceDidUpdateName(device: BLECDevice)

}

public extension BLECDeviceDelegate {
    func deviceForCharacteristic(charasteristic: CBCharacteristic, ofPeripheral peripheral: CBPeripheral) -> BLECCharacteristicDelegate? { return nil }

    func centralDidUpdateState(manager: BLECManager) {}
    func central(manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {}
    func central(manager: BLECManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {}
    func central(central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {}
    func central(central: BLECManager, didDisconnectDevice device: BLECDevice, error: NSError?) {}
    func central(central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {}

    func device(device: BLECDevice, didReadRSSI RSSI: Int, error: NSError?) {}
    func deviceDidUpdateName(device: BLECDevice) {}
}
