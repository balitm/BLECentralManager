//
//  DataCharacteristic.swift
//  BLECentralManager_Mac_Swift
//
//  Created by Balázs Kilvády on 7/8/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import BLECentralManager
import CoreBluetooth


class DataCharacteristic: BLECCharacteristicDelegate {

    weak var delegate: DataCharacteristicDelegate?

    func device(_ device: BLECDevice, didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device data characteristic <\(characteristic.uuid)> found!")
        device.peripheral?.setNotifyValue(true, for: characteristic)
        delegate?.dataFound()
    }

    func device(_ device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else {
            return
        }
        delegate?.dataRead(value.count)
    }
    
}
