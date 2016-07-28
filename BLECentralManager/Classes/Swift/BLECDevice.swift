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
    var writeResponse: ((NSError?) -> Void)?
}

public class BLECDevice {

    public enum Error: ErrorType {
        case NoPeripheral
        case InvalidCharacteristic
        case AlredyPending
    }

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

    public func readRSSI() throws {
        guard let peripheral = self.peripheral else {
            throw Error.NoPeripheral
        }

        peripheral.readRSSI()
    }

    public func writeValue(_ data: NSData,
                             forCharacteristic characteristic: CBCharacteristic,
                                               response: ((NSError?) -> Void)?) throws {
        guard let peripheral = self.peripheral else {
            throw Error.NoPeripheral
        }

        if response == nil {
            peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithoutResponse)
        } else {
            guard var charData = self.characteristics[characteristic.UUID] else {
                throw Error.InvalidCharacteristic
            }
            if charData.writeResponse != nil {
                throw Error.AlredyPending
            }
            charData.writeResponse = response!
            self.characteristics[characteristic.UUID] = charData
            peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
    }
}
