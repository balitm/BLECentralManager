//
//  ControlCharacteristic.swift
//  BLECentralManager_iOS_Swift
//
//  Created by Balázs Kilvády on 7/26/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import BLECentralManager
import CoreBluetooth


class ControlCharacteristic: BLECCharacteristicDelegate {

    weak var delegate: ControlCharacteristicDelegate?

    func device(device: BLECDevice,
                didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device control characteristic <\(characteristic.UUID)> found!")
        device.peripheral?.readValueForCharacteristic(characteristic)
    }

    func device(device: BLECDevice,
                didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                error: NSError?) {
        guard let data = characteristic.value else {
            DLog("No value!?")
            return
        }

        let byte: UInt8 = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: 1))[0]
        delegate?.controlUpdated(byte == 0 ? .Start : .Stop)
    }
}