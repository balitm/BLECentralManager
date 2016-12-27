//
//  BLECDevice.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/4/16.
//
//

import Foundation
import CoreBluetooth


struct BLECPeripheralState: OptionSet {
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
    var writeResponse: ((Error?) -> Void)?
}

open class BLECDevice {

    public enum DeviceError: Error {
        case noPeripheral
        case invalidCharacteristic
        case alredyPending
    }

    open var peripheral: CBPeripheral?
    var state = BLECPeripheralState.None
    open let UUID: Foundation.UUID
    var characteristics = [CBUUID: BLECDeviceData]()

    init(UUID uuid: Foundation.UUID) {
        UUID = uuid
        peripheral = nil
    }

    init(peripheral: CBPeripheral) {
        UUID = peripheral.identifier
        self.peripheral = peripheral
    }

    open func characteristicAt(_ characteristicIndex: Int, inServiceAt serviceIndex: Int) -> CBCharacteristic? {
        for (_, data) in characteristics {
            if data.serviceIndex == serviceIndex && data.characteristicIndex == characteristicIndex {
                return data.characteristic
            }
        }
        return nil
    }

    open func readRSSI() throws {
        guard let peripheral = self.peripheral else {
            throw DeviceError.noPeripheral
        }

        peripheral.readRSSI()
    }

    open func writeValue(_ data: Data,
                           forCharacteristic characteristic: CBCharacteristic,
                           response: ((Error?) -> Void)?) throws {
        guard let peripheral = self.peripheral else {
            throw DeviceError.noPeripheral
        }

        if response == nil {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } else {
            guard var charData = self.characteristics[characteristic.uuid] else {
                throw DeviceError.invalidCharacteristic
            }
            if charData.writeResponse != nil {
                throw DeviceError.alredyPending
            }
            charData.writeResponse = response!
            self.characteristics[characteristic.uuid] = charData
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}
