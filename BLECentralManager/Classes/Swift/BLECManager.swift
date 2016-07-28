//
//  BLECManager.swift
//  Pods
//
//  Created by Balázs Kilvády on 7/5/16.
//
//

import Foundation
import CoreBluetooth


public enum BLECentralState {
    case Init

    case Unknown
    case Unsupported
    case Unauthorized
    case PoweredOff
    case PoweredOn
    case Resetting

    case Searching
};


@objc public class BLECManager: NSObject {

    enum Error: ErrorType {
        case NotConnected
    }

    private let _config: BLECConfig
    private var _manager: CBCentralManager!
    private var _devices = [BLECDevice]()

    public var state = BLECentralState.Init
    public weak var delegate: BLECDeviceDelegate?


    public init?(config: BLECConfig, queue: dispatch_queue_t?) {
        _config = config
        super.init()
        _manager = CBCentralManager(delegate: self, queue: queue)
    }
}


// MARK: - CBCentralManagerDelegate methods

extension BLECManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(central: CBCentralManager) {
    DLog("centralManagerDidUpdateState")
        switch central.state {
        case .Unsupported:
            state = .Unsupported
        case .Unauthorized:
            state = .Unauthorized
        case .PoweredOff:
            state = .PoweredOff
        case .PoweredOn:
            state = .PoweredOn
            _search()
        case .Resetting:
            state = .Resetting
            DLog("resetting called, pairing refused?")
        case .Unknown:
            state = .Unknown;
        }
        DLog("Central manager state: \(state)")
        delegate?.centralDidUpdateState(self)
    }

    public func centralManager(central: CBCentralManager,
                               didDiscoverPeripheral peripheral: CBPeripheral,
                               advertisementData: [String : AnyObject],
                               RSSI: NSNumber) {
        DLog("didDiscoverPeripheral with advertisementData items: \(advertisementData.count)")
        #if DEBUG
            var i = 0
            for (key, value) in advertisementData {
                DLog("advertisementData \(i): \(key): \(value)")
                i += 1
            }
        #endif  // DEBUG

        let isConn = advertisementData[CBAdvertisementDataIsConnectable];
        if isConn == nil || isConn!.boolValue == false {
            DLog("isConn: \(isConn), not try to connect.")
            return;
        }

        //---- verify advertised services ----
        if let advertUUIDs = _config.advertServiceUUIDs {
            guard let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
                DLog("no services advertised.")
                return
            }

            for uuid in advertUUIDs {
                guard let _ = services.indexOf(uuid) else {
                    DLog("No advert service found: \(uuid)")
                    return
                }
            }
        }

        delegate?.central(self, didDiscoverPeripheral: peripheral, RSSI: RSSI.integerValue)
        _connect(peripheral)
    }

    public func centralManager(central: CBCentralManager,
                               didConnectPeripheral peripheral: CBPeripheral) {
        DLog("didConnectPeripheral")
        delegate?.central(self, didConnectPeripheral:peripheral)

        if peripheral.services?.count ?? 0 == 0 {
            //---- Get the services ----
            let uuids = _config.serviceUUIDs
            peripheral.discoverServices(uuids)
        } else {
            assert(false, "Is it reached ever?");
        }
    }

    public func centralManager(central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: NSError?) {
        //---- set device's state ----
        guard let index = _findDeviceByPeripheral(peripheral) else {
            DLog("device not found for \(peripheral)")
            return
        }
        assert(_devices[index].UUID == peripheral.identifier, "should be equal.");

        _devices[index].characteristics.removeAll()
        delegate?.central(self, didDisconnectDevice: _devices[index], error: error)

        _devices[index].peripheral = nil;
        _devices[index].state = .None;

        //---- workaround attempt for code 6, 10, ... errors ----
        if error != nil {
            _manager.stopScan()
            _search()
        }
    }

    public func centralManager(central: CBCentralManager,
                               didFailToConnectPeripheral peripheral: CBPeripheral,
                               error: NSError?) {
        DLog("Fail to connect to peripheral: \(peripheral) with error=\(error)")
        delegate?.central(self, didFailToConnectPeripheral: peripheral, error: error)
    }
}


// MARK: - CBCentralManagerDelegate methods

extension BLECManager: CBPeripheralDelegate {

    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error {
            DLog("service discover error: \(error.description)")
            return
        }

        var req = 0
        if let services = peripheral.services {
            for service in services {
                DLog("Found Service with UUID: \(service.UUID)")

                //---- find service in cofig ----
                let (sc, _) = _config.findServiceConfigFor(service.UUID)
                if let sc = sc {
                    if sc.type.contains(BLECServiceType.Required) {
                        req += 1
                    } else if !sc.type.contains(.Optional) {
                        DLog("Unexpected service found: \(service.UUID)")
                        _manager.cancelPeripheralConnection(peripheral)
                        return
                    }
                    let chars = sc.charcteristicUUIDs
                    peripheral.discoverCharacteristics(chars, forService: service)
                } else {
                    peripheral.discoverCharacteristics(nil, forService:service)
                }
            }
        }

        //---- check number of required services ----
        let requiredServices = _config.requiredServiceUUIDs
        let count = requiredServices?.count ?? 0
        if req != count {
            DLog("Not all the required services found.")
            _manager.cancelPeripheralConnection(peripheral)
        }
    }



    // MARK: Peripheral methods
    
    public func peripheral(peripheral: CBPeripheral,
                           didDiscoverCharacteristicsForService service: CBService,
                           error: NSError?) {
        DLog("didDiscoverCharacteristicForService: \(service.UUID)")

        let _quitFunc = { () in
            self._manager.cancelPeripheralConnection(peripheral)
        }

        guard let sChars = service.characteristics else {
            DLog("nil characteristics array.")
            return
        }
        let charCount = sChars.count
        guard charCount > 0 else {
            DLog("empty characteristics array.")
            return
        }

        let (sc, serviceIndex) = _config.findServiceConfigFor(service.UUID)
        var characteristics = [CBCharacteristic?](count: charCount, repeatedValue: nil)
        var delegates = [BLECCharacteristicDelegate?](count: charCount, repeatedValue: nil)
        var req = 0;

        if let scTemp = sc {
            if charCount < scTemp.requiredCharcteristicUUIDs?.count ?? 0 {
                DLog("Too few characteristic in service: \(service)")
                _quitFunc()
                return
            }
        }

        var idx = 0
        for aChar in sChars {
            if sc == nil {
                characteristics[idx] = aChar
                let charDelegate = delegate?.deviceForCharacteristic(aChar, ofPeripheral:peripheral)
                delegates[idx] = charDelegate
                idx += 1
            } else {
                let (cc, index) = sc!.findCharacteristicConfigFor(aChar.UUID)
                if let cc = cc {
                    if cc.type.contains(.Required) {
                        req += 1
                    } else if !cc.type.contains(.Optional) {
                        DLog("Unexpected characteristic found: \(aChar.UUID)")
                        _quitFunc()
                        return
                    }
                    characteristics[index] = aChar;
                    var charDelegate = cc.delegate
                    if charDelegate == nil {
                        charDelegate = delegate?.deviceForCharacteristic(aChar, ofPeripheral: peripheral)
                    }
                    delegates[index] = charDelegate
                } else {
                    DLog("Unexpected characteristic found: \(aChar.UUID)")
                    _quitFunc()
                    return
                }
            }
        }

        //---- successfuly read characteristics ----
        let devIdx = _findOrCreateDeviceByPeripheral(peripheral)
        idx = 0
        for aChar in characteristics {
            guard let characteristic = aChar else {
                DLog("nil characteristic at index \(idx)")
                _quitFunc()
                return
            }
            guard let charDelegate = delegates[idx] else {
                DLog("No delegete for characteristic \(aChar)")
                _quitFunc()
                return
            }
            let data = BLECDeviceData(characteristic: characteristic,
                                      delegate: charDelegate,
                                      serviceIndex: serviceIndex,
                                      characteristicIndex: idx,
                                      writeResponse: nil)
            _devices[devIdx].characteristics[characteristic.UUID] = data
            charDelegate.device(_devices[devIdx], didFindCharacteristic: characteristic)
            idx += 1
        }
        delegate?.central(self, didCheckCharacteristicsDevice: _devices[devIdx])
    }

    private func _didReadRSSI(peripheral: CBPeripheral,
                              RSSI: NSNumber?,
                              error: NSError?) {
        if let devIdx = _findDeviceByPeripheral(peripheral) {
            delegate?.device(_devices[devIdx],
                             didReadRSSI: RSSI?.integerValue ?? 0,
                             error:error)
        }
    }

    #if os(iOS)
    public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        _didReadRSSI(peripheral, RSSI: RSSI.integerValue, error: error)
    }
    #elseif os(OSX)
    public func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        _didReadRSSI(peripheral, RSSI: peripheral.RSSI, error: error)
    }
    #endif

    public func peripheralDidUpdateName(peripheral: CBPeripheral) {
        DLog("peripheral: \(peripheral) changed it's name to: \(peripheral.name)")
        if let devIdx = _findDeviceByPeripheral(peripheral) {
            delegate?.deviceDidUpdateName(_devices[devIdx])
        }
    }


    // MARK: Characteristic methods

    public func peripheral(peripheral: CBPeripheral,
                           didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                           error: NSError?) {
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("Unknow peripheral: \(peripheral)")
        }
        guard let data = _devices[devIdx].characteristics[characteristic.UUID] else {
            fatalError("No characteristic for \(peripheral) at \(devIdx)")
        }
        let delegate = data.delegate
        let device = _devices[devIdx]

        delegate.device(device,
                        didUpdateValueForCharacteristic: characteristic,
                        error:error)

        //---- check if readonly ----
        if characteristic.properties == .Read {
            let release = delegate.device(device, releaseReadonlyCharacteristic: characteristic)
            if release {
                // Release <BLECDeviceData data>.
                _devices[devIdx].characteristics[characteristic.UUID] = nil;
            }
        }
    }

    public func peripheral(peripheral: CBPeripheral,
                           didWriteValueForCharacteristic characteristic: CBCharacteristic,
                           error: NSError?) {
        DLog("Characteristic: \(characteristic) is written with error: \(error)")
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("No device for peripheral \(peripheral)")
        }
        let device = _devices[devIdx]

        assert(device.UUID == peripheral.identifier, "should be equal.")

        guard var data = device.characteristics[characteristic.UUID] else {
            fatalError("No characteristic data for \(characteristic) in device #\(devIdx):\(peripheral)")
        }

        if let writeResponse = data.writeResponse {
            writeResponse(error)
            data.writeResponse = nil
            device.characteristics[characteristic.UUID] = data
        } else {
            let delegate = data.delegate;
            delegate.device(device,
                            didWriteValueForCharacteristic: characteristic,
                            error: error)
        }
    }

    public func peripheral(peripheral: CBPeripheral,
                           didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic,
                           error: NSError?) {
        DLog("updated notification's state: \(characteristic)")
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("No device for peripheral \(peripheral)")
        }
        let device = _devices[devIdx]
        guard let data = device.characteristics[characteristic.UUID] else {
            fatalError("No characteristic data for \(characteristic) in device #\(devIdx):\(peripheral)")
        }
        let delegate = data.delegate
        delegate.device(device,
                        didUpdateNotificationStateForCharacteristic: characteristic,
                        error: error)
    }

}


// MARK: - private methods

extension BLECManager {

    private func _search() {
        struct Statics {
            static var token: dispatch_once_t = 0
            static var services: [CBUUID]?
        }
        dispatch_once(&Statics.token) {
            Statics.services = self._config.advertServiceUUIDs
        }

        state = .Searching;
        DLog(">>>> scan started.");
        _manager.scanForPeripheralsWithServices(Statics.services, options:_config.scanOptions)
        let reqServices = _config.requiredServiceUUIDs ?? [CBUUID]()
        let peers = _manager.retrieveConnectedPeripheralsWithServices(reqServices)

        DLog("already connetcted peripherals: %@", peers);
        if peers.count == 0 { return }

        for peripheral in peers {
            _connect(peripheral)
        }
    }

    private func _connect(peripheral: CBPeripheral) {
        if (peripheral.state == .Connected) {
            DLog("peripheral is connected already.")
            assert(peripheral.delegate === self,
                   "delegate is: \(peripheral.delegate)")
            if let index = _findDeviceByPeripheral(peripheral) {
                DLog("### we are connected to this peripheral already, state: 0x%04x",
                      _devices[index].state.rawValue)
                return
            }
        }

        //---- create device object for peripheral ----
        let index = _findOrCreateDeviceByUUID(peripheral.identifier)
        assert(_devices[index].peripheral == nil || _devices[index].peripheral === peripheral,
               "check peripheral")
        _devices[index].peripheral = peripheral

        DLog("connecting...")
        peripheral.delegate = self
        _manager.connectPeripheral(peripheral, options: _config.connectOptions)
    }

    private func _disconnect(device: BLECDevice) throws {
        guard let peripheral = device.peripheral else {
            throw Error.NotConnected
        }
        guard peripheral.state == .Connected else {
            throw Error.NotConnected
        }

        _manager.cancelPeripheralConnection(peripheral)
    }



    private func _findDeviceByUUID(uuid: NSUUID) -> Int? {
        return _devices.indexOf { uuid == $0.UUID }
    }

    private func _findOrCreateDeviceByUUID(uuid: NSUUID) -> Int {
        if let index = _findDeviceByUUID(uuid) {
            return index
        }

        _devices.append(BLECDevice(UUID: uuid))
        return _devices.endIndex - 1;
    }

    private func _findDeviceByPeripheral(peripheral: CBPeripheral) -> Int? {
        return _devices.indexOf { peripheral === $0.peripheral }
    }

    private func _findOrCreateDeviceByPeripheral(peripheral: CBPeripheral) -> Int {
        if let index = _findDeviceByPeripheral(peripheral) {
            return index
        }

        _devices.append(BLECDevice(peripheral: peripheral))
        return _devices.endIndex - 1;
    }

}