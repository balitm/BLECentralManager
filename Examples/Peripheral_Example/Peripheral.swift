//
//  Peripheral.swift
//  Peripheral_Example
//
//  Created by Balázs Kilvády on 6/23/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import Foundation
import CoreBluetooth

class Peripheral: NSObject {

    fileprivate let _kDataServiceUUID = CBUUID(string: "965F6F06-2198-4F4F-A333-4C5E0F238EB7")
    fileprivate let _kDataCharacteristicUUID = CBUUID(string: "89E63F02-9932-4DF1-91C7-A574C880EFBF")
    fileprivate let _kControlCharacteristicUUID = CBUUID(string: "88359D38-DEA0-4FA4-9DD2-0A47E2B794BE")

    fileprivate weak var _delegate: PeripheralDelegate!
    fileprivate var _sampleData: Data?
    fileprivate var _repeatCount: UInt = 0

    fileprivate var _manager: CBPeripheralManager!
    fileprivate var _dataCharacteristic: CBMutableCharacteristic?
    fileprivate var _controlCharacteristic: CBMutableCharacteristic?
    fileprivate var _dataService: CBMutableService?
    fileprivate var _serviceRequiresRegistration = false
    fileprivate var _subscribers = [CBCentral]()
    var subscribersCount: Int {
        get {
            return _subscribers.count
        }
    }


    init(delegate: PeripheralDelegate) {
        super.init()
        _delegate = delegate
        _manager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }

    fileprivate func _enableDataService() {
        // If the service is already registered, we need to re-register it again.
        _disableDataService()

        // Create a BTLE Peripheral Service and set it to be the primary. If it
        // is not set to the primary, it will not be found when the app is in the
        // background.
        _dataService = CBMutableService(type: _kDataServiceUUID, primary: true)

        // Set up the characteristic in the service. This characteristic is only
        // readable through subscription (CBCharacteristicsPropertyNotify)
        _dataCharacteristic = CBMutableCharacteristic(type: _kDataCharacteristicUUID,
                                                      properties: .notify,
                                                      value: nil,
                                                      permissions: .readable)

        _controlCharacteristic = CBMutableCharacteristic(type: _kControlCharacteristicUUID,
                                                         properties: [.read, .write],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])

        guard let service = _dataService,
            let characteristic = _dataCharacteristic,
            let ctrlCharacteristic = _controlCharacteristic else {
                return
        }

        // Assign the characteristic.
        service.characteristics = [characteristic, ctrlCharacteristic]

        // Add the service to the peripheral manager.
        _manager.add(service)
    }

    fileprivate func _disableDataService() {
        if let service = _dataService {
            _manager.remove(service)
            _dataService = nil
        }
    }

    // Called when the BTLE advertisments should start.
    func startAdvertising() {
        if (_manager.isAdvertising) {
            _manager.stopAdvertising()
        }

        let advertisment = [CBAdvertisementDataServiceUUIDsKey : [_kDataServiceUUID]]
        _manager.startAdvertising(advertisment)
    }

    func stopAdvertising() {
        _manager.stopAdvertising()
    }

    fileprivate func _notifySubscribers() {
        while _repeatCount > 0 {
            let res = _manager.updateValue(_sampleData!,
                                           for: _dataCharacteristic!,
                                           onSubscribedCentrals: nil)
//            DLog("Sending \(_sampleData?.bytes) data, rc: \(_repeatCount), max: \(_subscribers.count > 0 ? _subscribers[0].maximumUpdateValueLength : 0)")
            if (!res) {
//                DLog("Failed to send data, buffering data for retry once ready.")
                // _pendingData = _sampleData
                break
            } else {
                _repeatCount -= 1
            }
        }
    }

    func sendToSubscribers(_ data: Data, repeatCount: UInt) {
        guard _manager.state == .poweredOn else {
            _delegate.logMessage("sendToSubscribers: peripheral not ready for sending state: \(_manager.state)")
            return
        }

        guard let _ = _dataCharacteristic else {
            return
        }

        _repeatCount = repeatCount
        _sampleData = data
//        DLog("repeat count set to \(repeatCount)")
        _notifySubscribers()
    }
}


extension Peripheral: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            _delegate.logMessage("Peripheral powered on.")
            DLog("Peripheral powered on.")
            _enableDataService()
        case .poweredOff:
            _delegate.logMessage("Peripheral powered off.")
            _disableDataService()
        case .resetting:
            _delegate.logMessage("Peripheral resetting.")
            _serviceRequiresRegistration = true
        case .unauthorized:
            _delegate.logMessage("Peripheral unauthorized.")
            _serviceRequiresRegistration = true
        case .unknown:
            _delegate.logMessage("Peripheral unknown.")
            _serviceRequiresRegistration = true
        case .unsupported:
            _delegate.logMessage("Peripheral unsupported.")
            _serviceRequiresRegistration = true
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didAdd service: CBService,
                                         error: Error?) {
        guard error == nil else {
            _delegate.logMessage("Failed to add a service: : \(error)")
            return
        }

        // As soon as the service is added, we should start advertising.
        if service == _dataService {
            _controlCharacteristic?.value = Data(bytes: UnsafePointer<UInt8>([UInt8(0)]), count: 1)
            startAdvertising()
            DLog("Peripheral advertising...")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        assert(!_subscribers.contains(central))
        _subscribers.append(central)
        _manager.setDesiredConnectionLatency(.low, for: central)
        DLog("Appended - subscribers: \(_subscribers)")
        _delegate.central(central.identifier.uuidString,
                          didSubscribeToCharacteristic: characteristic.uuid.uuidString)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        if let index = _subscribers.index(of: central) {
            _subscribers.remove(at: index)
            DLog("Removed - subscribers: \(_subscribers)")
        } else {
            assert(false)
        }
        _delegate.central(central.identifier.uuidString,
                          didUnsubscribeFromCharacteristic: characteristic.uuid.uuidString)
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                              error: Error?) {
        guard error == nil else {
            _delegate.logMessage("Failed to start advertising: \(error).")
            return
        }

        _delegate.logMessage("advertising started.")
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
//        DLog("current repeat count is \(_repeatCount)")
        _notifySubscribers()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveRead request: CBATTRequest) {
        guard let ctrlCharacteristic = _controlCharacteristic else {
            peripheral.respond(to: request, withResult: .invalidHandle)
            return
        }
        DLog("value to send: \(ctrlCharacteristic.value)")
        request.value = ctrlCharacteristic.value
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest]) {
        guard let ctrlCharacteristic = _controlCharacteristic else {
            peripheral.respond(to: requests[0], withResult: .invalidHandle)
            return
        }
        for req in requests {
            if req.characteristic != _controlCharacteristic {
                continue
            }
            guard let value = req.value else {
                continue
            }
            assert(req.offset == 0 && value.count == 1)
            ctrlCharacteristic.value = value
            let array = value.withUnsafeBytes {
                [UInt8](UnsafeBufferPointer(start: $0, count: 1))
            }
            let byte: UInt8 = array[0]
            _delegate.sending(byte != 0)
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }
}
