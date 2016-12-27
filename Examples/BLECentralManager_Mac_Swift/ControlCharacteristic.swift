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

    func device(_ device: BLECDevice,
                didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device control characteristic <\(characteristic.uuid)> found!")
        device.peripheral?.readValue(for: characteristic)
    }

    func device(_ device: BLECDevice,
                didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                error: Error?) {
        guard let data = characteristic.value else {
            DLog("No value!?")
            return
        }

        let array = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
        }
        let byte: UInt8 = array[0]
        delegate?.controlDidUpdate(byte == 0 ? .start : .stop)
    }
}
