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
    case initial
    case unknown
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
    case resetting

    case searching
}


@objc open class BLECManager: NSObject {

    enum ManagerError: Error {
        case notConnected
    }

    fileprivate let _config: BLECConfig
    fileprivate var _manager: CBCentralManager!
    fileprivate var _devices = [BLECDevice]()

    open var state = BLECentralState.initial
    open weak var delegate: BLECDeviceDelegate?


    public init?(config: BLECConfig, queue: DispatchQueue? = nil) {
        _config = config
        super.init()
        _manager = CBCentralManager(delegate: self, queue: queue)
    }
}


// MARK: - CBCentralManagerDelegate methods

extension BLECManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    DLog("centralManagerDidUpdateState")
        switch central.state {
        case .unsupported:
            state = .unsupported
        case .unauthorized:
            state = .unauthorized
        case .poweredOff:
            state = .poweredOff
        case .poweredOn:
            if !_search() { return }
        case .resetting:
            state = .resetting
            DLog("resetting called, pairing refused?")
        case .unknown:
            state = .unknown
        }
        DLog("Central manager state: \(state)")
        delegate?.centralDidUpdateState(self)
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        DLog("didDiscoverPeripheral with advertisementData items: \(advertisementData.count)")
        #if DEBUG
            var i = 0
            for (key, value) in advertisementData {
                DLog("advertisementData \(i): \(key): \(value)")
                i += 1
            }
        #endif  // DEBUG

        let isConn = advertisementData[CBAdvertisementDataIsConnectable]
        if isConn == nil || (isConn! as AnyObject).boolValue == false {
            DLog("isConn: \(isConn), not try to connect.")
            return
        }

        //---- verify advertised services ----
        if let advertUUIDs = _config.advertServiceUUIDs {
            guard let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
                DLog("no services advertised.")
                return
            }

            for uuid in advertUUIDs {
                guard let _ = services.index(of: uuid) else {
                    DLog("No advert service found: \(uuid)")
                    return
                }
            }
        }

        delegate?.central(self, didDiscoverPeripheral: peripheral, RSSI: RSSI.intValue)
        _connect(peripheral)
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        DLog("didConnectPeripheral, delegate: \(delegate)")
        delegate?.central(self, didConnectPeripheral:peripheral)

        //---- Get the services ----
        let uuids = _config.serviceUUIDs
        peripheral.discoverServices(uuids)
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        //---- set device's state ----
        guard let index = _findDeviceByPeripheral(peripheral) else {
            DLog("device not found for \(peripheral)")
            return
        }
        assert(_devices[index].UUID == peripheral.identifier, "should be equal.")

        _devices[index].characteristics.removeAll()
        DLog("didDisonnectPeripheral, delegate: \(delegate)")
        delegate?.central(self, didDisconnectDevice: _devices[index], error: error)

        _devices[index].peripheral = nil
        _devices[index].state = .None

        //---- workaround attempt for code 6, 10, ... errors ----
        if error != nil {
            _manager.stopScan()
            _ = _search()
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        DLog("Fail to connect to peripheral: \(peripheral) with error=\(error)")
        delegate?.central(self, didFailToConnectPeripheral: peripheral, error: error)
    }
}


// MARK: - CBCentralManagerDelegate methods

extension BLECManager: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            DLog("service discover error: \((error as NSError).description)")
            return
        }

        var req = 0
        if let services = peripheral.services {
            for service in services {
                DLog("Found Service with UUID: \(service.uuid)")

                //---- find service in cofig ----
                let (sc, _) = _config.findServiceConfigFor(service.uuid)
                if let sc = sc {
                    if sc.type.contains(.required) {
                        req += 1
                    } else if !sc.type.contains(.optional) {
                        DLog("Unexpected service found: \(service.uuid)")
                        _manager.cancelPeripheralConnection(peripheral)
                        return
                    }
                    let chars = sc.charcteristicUUIDs
                    peripheral.discoverCharacteristics(chars, for: service)
                } else {
                    peripheral.discoverCharacteristics(nil, for:service)
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
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        DLog("didDiscoverCharacteristicForService: \(service.uuid)")

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

        let (sc, serviceIndex) = _config.findServiceConfigFor(service.uuid)
        var characteristics = [CBCharacteristic?](repeating: nil, count: charCount)
        var delegates = [BLECCharacteristicDelegate?](repeating: nil, count: charCount)
        var req = 0

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
                let (cc, index) = sc!.findCharacteristicConfigFor(aChar.uuid)
                if let cc = cc {
                    if cc.type.contains(.required) {
                        req += 1
                    } else if !cc.type.contains(.optional) {
                        DLog("Unexpected characteristic found: \(aChar.uuid)")
                        _quitFunc()
                        return
                    }
                    characteristics[index] = aChar
                    var charDelegate = cc.delegate
                    if charDelegate == nil {
                        charDelegate = delegate?.deviceForCharacteristic(aChar, ofPeripheral: peripheral)
                    }
                    delegates[index] = charDelegate
                } else {
                    DLog("Unexpected characteristic found: \(aChar.uuid)")
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
            _devices[devIdx].characteristics[characteristic.uuid] = data
            charDelegate.device(_devices[devIdx], didFindCharacteristic: characteristic)
            idx += 1
        }
        delegate?.central(self, didCheckCharacteristicsDevice: _devices[devIdx])
    }

    fileprivate func _didReadRSSI(_ peripheral: CBPeripheral,
                              RSSI: NSNumber?,
                              error: Error?) {
        if let devIdx = _findDeviceByPeripheral(peripheral) {
            delegate?.device(_devices[devIdx],
                             didReadRSSI: RSSI?.intValue ?? 0,
                             error:error)
        }
    }

    #if os(iOS)
    public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        _didReadRSSI(peripheral, RSSI: RSSI, error: error)
    }
    #elseif os(OSX)
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        _didReadRSSI(peripheral, RSSI: peripheral.rssi, error: error)
    }
    #endif

    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        DLog("peripheral: \(peripheral) changed it's name to: \(peripheral.name)")
        if let devIdx = _findDeviceByPeripheral(peripheral) {
            delegate?.deviceDidUpdateName(_devices[devIdx])
        }
    }


    // MARK: Characteristic methods

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("Unknow peripheral: \(peripheral)")
        }
        guard let data = _devices[devIdx].characteristics[characteristic.uuid] else {
            fatalError("No characteristic for \(peripheral) at \(devIdx)")
        }
        let delegate = data.delegate
        let device = _devices[devIdx]

        delegate.device(device,
                        didUpdateValueForCharacteristic: characteristic,
                        error: error)

        //---- check if readonly ----
        if characteristic.properties == .read {
            let release = delegate.device(device, releaseReadonlyCharacteristic: characteristic)
            if release {
                // Release <BLECDeviceData data>.
                _devices[devIdx].characteristics[characteristic.uuid] = nil
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        DLog("Characteristic: \(characteristic) is written with error: \(error)")
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("No device for peripheral \(peripheral)")
        }
        let device = _devices[devIdx]

        assert(device.UUID as UUID == peripheral.identifier, "should be equal.")

        guard var data = device.characteristics[characteristic.uuid] else {
            fatalError("No characteristic data for \(characteristic) in device #\(devIdx):\(peripheral)")
        }

        if let writeResponse = data.writeResponse {
            writeResponse(error)
            data.writeResponse = nil
            device.characteristics[characteristic.uuid] = data
        } else {
            let delegate = data.delegate
            delegate.device(device,
                            didWriteValueForCharacteristic: characteristic,
                            error: error)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?) {
        DLog("updated notification's state: \(characteristic)")
        guard let devIdx = _findDeviceByPeripheral(peripheral) else {
            fatalError("No device for peripheral \(peripheral)")
        }
        let device = _devices[devIdx]
        guard let data = device.characteristics[characteristic.uuid] else {
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

    fileprivate func _search() -> Bool {
        guard state != .searching else { return false }
        state = .searching
        DLog(">>>> scan started.")
        _manager.scanForPeripherals(withServices: _config.advertServiceUUIDs, options:_config.scanOptions)
        let reqServices = _config.requiredServiceUUIDs ?? [CBUUID]()
        let peers = _manager.retrieveConnectedPeripherals(withServices: reqServices)

        DLog("already connetcted peripherals: \(peers)")
        if peers.count == 0 { return true }

        peers.forEach {
            _connect($0)
        }
        return true
    }

    fileprivate func _connect(_ peripheral: CBPeripheral) {
        if (peripheral.state == .connected) {
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
        _manager.connect(peripheral, options: _config.connectOptions)
    }

    fileprivate func _disconnect(_ device: BLECDevice) throws {
        guard let peripheral = device.peripheral else {
            throw ManagerError.notConnected
        }
        guard peripheral.state == .connected else {
            throw ManagerError.notConnected
        }

        _manager.cancelPeripheralConnection(peripheral)
    }



    fileprivate func _findDeviceByUUID(_ uuid: UUID) -> Int? {
        return _devices.index { uuid == $0.UUID as UUID }
    }

    fileprivate func _findOrCreateDeviceByUUID(_ uuid: UUID) -> Int {
        if let index = _findDeviceByUUID(uuid) {
            return index
        }

        _devices.append(BLECDevice(UUID: uuid))
        return _devices.endIndex - 1
    }

    fileprivate func _findDeviceByPeripheral(_ peripheral: CBPeripheral) -> Int? {
        return _devices.index { peripheral === $0.peripheral }
    }

    fileprivate func _findOrCreateDeviceByPeripheral(_ peripheral: CBPeripheral) -> Int {
        if let index = _findDeviceByPeripheral(peripheral) {
            return index
        }

        _devices.append(BLECDevice(peripheral: peripheral))
        return _devices.endIndex - 1
    }

}
