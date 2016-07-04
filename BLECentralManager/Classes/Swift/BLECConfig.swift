//
//  BLECConfig.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/4/16.
//
//

import Foundation
import CoreBluetooth


public struct BLECServiceType: OptionSetType {
    public var rawValue: UInt

    public static let Any = BLECServiceType(rawValue: 0x1)
    public static let Advertised = BLECServiceType(rawValue: 0x2)
    public static let Required = BLECServiceType(rawValue: 0x5)
    public static let Optional = BLECServiceType(rawValue: 0x8)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public struct BLECCharacteristicType: OptionSetType {
    public var rawValue: UInt

    public static let Any = BLECCharacteristicType(rawValue: 0x1)
    public static let Required = BLECCharacteristicType(rawValue: 0x2)
    public static let Optional = BLECCharacteristicType(rawValue: 0x4)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public enum BLECentralType {
    case OnePheriperal
    case MultiPheriperal
}


//----------------------------------------------------------------------------
// BLECCharacteristicConfig
//----------------------------------------------------------------------------
public struct BLECCharacteristicConfig {
    public var type: BLECCharacteristicType
    public var UUID: CBUUID
    public var delegate: BLECCharacteristicDelegate?

    public init(type: BLECCharacteristicType, UUID uuid: String, delegate: BLECCharacteristicDelegate?) {
        self.type = type
        self.UUID = CBUUID(string: uuid)
        self.delegate = delegate
    }
}


//----------------------------------------------------------------------------
// BLECServiceConfig
//----------------------------------------------------------------------------
public struct BLECServiceConfig {

    public var type: BLECServiceType
    public var UUID: CBUUID
    public var characteristics: [BLECCharacteristicConfig]?
    public var charecteristicCount: Int {
        get {
            return characteristics != nil ? characteristics!.count : 0
        }
    }

    public init(type: BLECServiceType, UUID: String, characteristics: [BLECCharacteristicConfig]?) {
        self.type = type
        self.UUID = CBUUID(string: UUID)
        self.characteristics = characteristics
    }

    private func _selectCharUUIDs(type: BLECCharacteristicType) -> [CBUUID]? {
        guard let chars = self.characteristics else {
            return nil;
        }

        var uuids = [CBUUID]()
        uuids.reserveCapacity(chars.count)
        for characteristic in chars {
            if type == .Any || characteristic.type.contains(type) {
                uuids.append(characteristic.UUID)
            }
        }
        return uuids.count == 0 ? nil : uuids
    }


    var requiredCharcteristicUUIDs: [CBUUID]? {
        return _selectCharUUIDs(.Required)
    }

    var charcteristicUUIDs: [CBUUID]? {
        return _selectCharUUIDs(.Any)
    }

    func findCharacteristicConfigFor(UUID: CBUUID) -> (BLECCharacteristicConfig?, Int) {
        guard let chars = characteristics else {
            return (nil, -1)
        }

        for (index, aChar) in chars.enumerate() {
            if UUID.isEqual(aChar.UUID) {
                return (aChar, index)
            }
        }
        return (nil, -1);
    }
}


//----------------------------------------------------------------------------
// BLECConfig
//----------------------------------------------------------------------------
public struct BLECConfig {
    public var type: BLECentralType
    public var scanOptions: [String : AnyObject]?
    public var connectOptions: [String : AnyObject]?
    public var services: [BLECServiceConfig]?

    public init(type: BLECentralType, services: [BLECServiceConfig]?) {
        self.type = type
        self.services = services
    }

    private func _selectServiceUUIDs(type: BLECServiceType) -> [CBUUID]? {
        guard let servs = self.services else {
            return nil;
        }

        var uuids = [CBUUID]()
        uuids.reserveCapacity(servs.count)
        for service in servs {
            if type == .Any || service.type.contains(type) {
                uuids.append(service.UUID)
            }
        }
        return uuids.count == 0 ? nil : uuids
    }

    var advertServiceUUIDs: [CBUUID]? {
        return _selectServiceUUIDs(.Advertised)
    }

    var requiredServiceUUIDs: [CBUUID]? {
        return _selectServiceUUIDs(.Required)
    }
    
    var serviceUUIDs: [CBUUID]? {
        return _selectServiceUUIDs(.Any)
    }

    func findServiceConfigFor(UUID: CBUUID) -> (BLECServiceConfig?, Int) {
        guard let servs = self.services else {
            return (nil, -1)
        }

        for (index, servie) in servs.enumerate() {
            if UUID.isEqual(servie.UUID) {
                return (servie, index)
            }
        }
        return (nil, -1)
    }
}
