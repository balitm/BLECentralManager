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
    private let _name: String

    init(name: String) {
        _name = name
    }

    func device(device: BLECDevice,
                didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device info characteristic <\(characteristic.UUID)> found!" )
        device.peripheral?.readValueForCharacteristic(characteristic)
    }


    func device(device: BLECDevice,
                didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                error: NSError?) {
        guard error == nil else {
            DLog("characteristic value read with error: \(error)")
            return
        }
        guard let data = characteristic.value else {
            DLog("No data when it is updated?!")
            return
        }

        guard let value = String(data: data, encoding: NSUTF8StringEncoding) else {
            DLog("Cannot decode a string value?!")
            return
        }
        delegate?.infoCharacteristicName(_name, value: value)
    }

    func device(device: BLECDevice, releaseReadonlyCharacteristic characteristic: CBCharacteristic) -> Bool {
        return true
    }
}
