//
//  InfoCharacteristic.swift
//  BLECentralManager_Mac_Swift
//
//  Created by Balázs Kilvády on 7/8/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import BLECentralManager
import CoreBluetooth


class InfoCharacteristic: BLECCharacteristicDelegate {

    var delegate: InfoCharacteristicDelegate?
    fileprivate let _name: String

    init(name: String) {
        _name = name
    }

    func device(_ device: BLECDevice,
                didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device info characteristic <\(characteristic.uuid)> found!" )
        device.peripheral?.readValue(for: characteristic)
    }


    func device(_ device: BLECDevice,
                didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                error: Error?) {
        guard error == nil else {
            DLog("characteristic value read with error: \(error)")
            return
        }
        guard let data = characteristic.value else {
            DLog("No data when it is updated?!")
            return
        }

        guard let value = String(data: data, encoding: String.Encoding.utf8) else {
            DLog("Cannot decode a string value?!")
            return
        }
        delegate?.infoCharacteristicName(_name, value: value)
    }

    func device(_ device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool {
        return true
    }
}
