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

    private let _kDataServiceUUID = CBUUID(string: "965F6F06-2198-4F4F-A333-4C5E0F238EB7")
    private let _kDataCharacteristicUUID = CBUUID(string: "89E63F02-9932-4DF1-91C7-A574C880EFBF")

    private weak var _delegate: PeripheralDelegate!
    private var _sampleData: NSData?
    private var _repeatCount: UInt = 0

    private var _manager: CBPeripheralManager!
    private var _dataCharacteristic: CBMutableCharacteristic?
    private var _dataService: CBMutableService?
    private var _serviceRequiresRegistration = false;
//    private var _pendingData: NSData?
    private var _subscribers = [CBCentral]();
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

    private func _enableDataService() {
        // If the service is already registered, we need to re-register it again.
        _disableDataService()

        // Create a BTLE Peripheral Service and set it to be the primary. If it
        // is not set to the primary, it will not be found when the app is in the
        // background.
        _dataService = CBMutableService(type: _kDataServiceUUID,
                                        primary: true)

        // Set up the characteristic in the service. This characteristic is only
        // readable through subscription (CBCharacteristicsPropertyNotify)
        _dataCharacteristic = CBMutableCharacteristic(type: _kDataCharacteristicUUID,
                                                      properties: .Notify,
                                                      value: nil,
                                                      permissions: .Readable)

        guard let service = _dataService, characteristic = _dataCharacteristic else {
            return;
        }

        // Assign the characteristic.
        service.characteristics = [characteristic]

        // Add the service to the peripheral manager.
        _manager.addService(service)
    }

    private func _disableDataService() {
        if let service = _dataService {
            _manager.removeService(service)
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

    private func _notifySubscribers() {
        while _repeatCount > 0 {
            let res = _manager.updateValue(_sampleData!,
                                           forCharacteristic: _dataCharacteristic!,
                                           onSubscribedCentrals: nil)
//            DLog("Sending \(_sampleData?.bytes) data, rc: \(_repeatCount), max: \(_subscribers.count > 0 ? _subscribers[0].maximumUpdateValueLength : 0)")
            if (!res) {
//                DLog("Failed to send data, buffering data for retry once ready.")
                // _pendingData = _sampleData;
                break
            } else {
                _repeatCount -= 1
            }
        }
    }

    func sendToSubscribers(data: NSData, repeatCount: UInt) {
        guard _manager.state == .PoweredOn else {
            _delegate.logMessage("sendToSubscribers: peripheral not ready for sending state: \(_manager.state)")
            return;
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

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            _delegate.logMessage("Peripheral powered on.")
            DLog("Peripheral powered on.")
            _enableDataService()
        case .PoweredOff:
            _delegate.logMessage("Peripheral powered off.")
            _disableDataService()
        case .Resetting:
            _delegate.logMessage("Peripheral resetting.")
            _serviceRequiresRegistration = true
        case .Unauthorized:
            _delegate.logMessage("Peripheral unauthorized.")
            _serviceRequiresRegistration = true
        case .Unknown:
            _delegate.logMessage("Peripheral unknown.")
            _serviceRequiresRegistration = true
        case .Unsupported:
            _delegate.logMessage("Peripheral unsupported.")
            _serviceRequiresRegistration = true
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager,
                           didAddService service: CBService,
                                         error: NSError?) {
        guard error == nil else {
            _delegate.logMessage("Failed to add a service: : \(error)")
            return
        }

        // As soon as the service is added, we should start advertising.
        if service == _dataService {
            startAdvertising()
            DLog("Peripheral advertising...")
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        assert(!_subscribers.contains(central))
        _subscribers.append(central)
        _manager.setDesiredConnectionLatency(.Low, forCentral: central)
        DLog("Appended - subscribers: \(_subscribers)")
        _delegate.central(central.identifier.UUIDString,
                          didSubscribeToCharacteristic: characteristic.UUID.UUIDString)
    }

    func peripheralManager(peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        if let index = _subscribers.indexOf(central) {
            _subscribers.removeAtIndex(index)
            DLog("Removed - subscribers: \(_subscribers)")
        } else {
            assert(false)
        }
        _delegate.central(central.identifier.UUIDString,
                          didUnsubscribeFromCharacteristic: characteristic.UUID.UUIDString)
    }

    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager,
                                              error: NSError?) {
        guard error == nil else {
            _delegate.logMessage("Failed to start advertising: \(error).")
            return
        }

        _delegate.logMessage("advertising started.")
    }

    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
//        DLog("current repeat count is \(_repeatCount)")
        _notifySubscribers()
    }
}
