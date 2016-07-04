//
//  BLECCharacteristicDelegate.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/4/16.
//
//

import Foundation
import CoreBluetooth


public protocol BLECCharacteristicDelegate: class {
    func device(device: BLECDevice, didFindCharacteristic characteristic: CBCharacteristic)

    func device(device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    func device(device: BLECDevice, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    func device(device: BLECDevice, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    func device(device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool
}

public extension BLECCharacteristicDelegate {
    func device(device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {}
    func device(device: BLECDevice, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {}
    func device(device: BLECDevice, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {}
    func device(device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool { return true }
}
