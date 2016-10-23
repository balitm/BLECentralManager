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
    func device(_ device: BLECDevice, didFindCharacteristic characteristic: CBCharacteristic)

    func device(_ device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: Error?)
    func device(_ device: BLECDevice, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: Error?)
    func device(_ device: BLECDevice, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: Error?)
    func device(_ device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool
}

public extension BLECCharacteristicDelegate {
    func device(_ device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: Error?) {}
    func device(_ device: BLECDevice, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: Error?) {}
    func device(_ device: BLECDevice, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: Error?) {}
    func device(_ device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool { return true }
}
