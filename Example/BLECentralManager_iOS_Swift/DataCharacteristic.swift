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

    func device(device: BLECDevice, didFindCharacteristic characteristic: CBCharacteristic) {
        DLog("device data characteristic <\(characteristic.UUID)> found!")
        device.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
        delegate?.dataFound()
    }

    func device(device: BLECDevice, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard let value = characteristic.value else {
            return
        }
        delegate?.dataRead(value.length)
    }
    
}
