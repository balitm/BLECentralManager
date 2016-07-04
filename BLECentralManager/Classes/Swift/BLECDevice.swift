//
//  BLECDevice.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/4/16.
//
//

import Foundation
import CoreBluetooth


struct BLECPeripheralState: OptionSetType {
    let rawValue: UInt

    static let None       = BLECPeripheralState(rawValue: 0)
    static let Discovered = BLECPeripheralState(rawValue: 0x01)
    static let Connected  = BLECPeripheralState(rawValue: 0x02)

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

struct BLECDeviceData {
    var characteristic: CBCharacteristic
    var delegate: BLECCharacteristicDelegate
    var serviceIndex: Int
    var characteristicIndex: Int
}

public struct BLECDevice {
    public var peripheral: CBPeripheral?
    var state = BLECPeripheralState.None
    public let UUID: NSUUID
    var characteristics = [CBUUID: BLECDeviceData]()

    init(UUID uuid: NSUUID) {
        UUID = uuid;
        peripheral = nil;
    }

    init(peripheral: CBPeripheral) {
        UUID = peripheral.identifier
        self.peripheral = peripheral
    }

    public func characteristicAt(characteristicIndex: Int, inServiceAt serviceIndex: Int) -> CBCharacteristic? {
        for (_, data) in characteristics {
            if data.serviceIndex == serviceIndex && data.characteristicIndex == characteristicIndex {
                return data.characteristic;
            }
        }
        return nil;
    }

    public func readRSSI() {
        peripheral?.readRSSI()
    }
}
