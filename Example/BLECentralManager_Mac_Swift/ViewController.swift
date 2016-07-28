//
//  ViewController.swift
//  BLECentralManager_Mac_Swift
//
//  Created by Balázs Kilvády on 6/30/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import Cocoa
import CoreBluetooth
import BLECentralManager


class ViewController: NSViewController {

    private static let _kMaxKbps = 1024.0 * 100.0

    private var _manager: BLECManager!
    private var _timer: NSTimer?
    private var _dataSize: Int = 0
    private var _device: BLECDevice?

    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var rssiLabel: NSTextField!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet var logView: NSTextView!


    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let dataChar = DataCharacteristic()
        dataChar.delegate = self;

        let controlChar = ControlCharacteristic()
        controlChar.delegate = self

        var infoChars = [
            InfoCharacteristic(name: "Manufacturer"),
            InfoCharacteristic(name: "Firmware"),
            InfoCharacteristic(name: "HwRev"),
            InfoCharacteristic(name: "SwRev")
        ]
        for i in 0..<infoChars.endIndex { infoChars[i].delegate = self }

        let config = BLECConfig(type: .OnePheriperal, services: [
            BLECServiceConfig(
                type: [.Advertised, .Required],
                UUID: "965F6F06-2198-4F4F-A333-4C5E0F238EB7",
                characteristics: [
                    BLECCharacteristicConfig(
                        type: .Required,
                        UUID: "89E63F02-9932-4DF1-91C7-A574C880EFBF",
                        delegate: dataChar),
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "88359D38-DEA0-4FA4-9DD2-0A47E2B794BE",
                        delegate: controlChar)
                ]),
            BLECServiceConfig(type: .Optional,
                UUID: "180a",
                characteristics: [
                    // Manufacturer Name String characteristic.
                    BLECCharacteristicConfig(
                        type: .Required,
                        UUID: "2a29",
                        delegate: infoChars[0]),

                    // board
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a26",
                        delegate: infoChars[1]),

                    // HwRev
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a27",
                        delegate: infoChars[2]),

                    // SwRev
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a28",
                        delegate: infoChars[3])
                ])
            ])

        _manager = BLECManager(config: config, queue: nil)
        _manager.delegate = self;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @objc private func _update() {
        //---- compute speed ----
        let bitSize = Double(_dataSize) * 8.0
        self.progressView.doubleValue = bitSize / Double(ViewController._kMaxKbps)
        let numString = String(format: "%0.2f", bitSize / 1024.0)
        self.speedLabel.stringValue = numString
        _dataSize = 0

        //---- read RSSI ----
        do {
            try _device?.readRSSI()
        } catch BLECDevice.Error.InvalidCharacteristic {
            print("Characteristic is not maintained by BLECManager.")
        } catch BLECDevice.Error.NoPeripheral {
            print("Peripheral is not maintained by BLECManager.")
        } catch {
            assert(false)
        }
    }
}


//............................................................................
// MARK: - Device extension.
//............................................................................

extension ViewController: BLECDeviceDelegate {

    private func _stateName(state: BLECentralState) -> String {
        switch (state) {
        case .Init:
            return "BLECStateInit"
        case .Unknown:
            return "BLECStateUnknown"
        case .Unsupported:
            return "BLECStateUnsupported"
        case .Unauthorized:
            return "BLECStateUnauthorized"
        case .PoweredOff:
            return "BLECStatePoweredOff"
        case .PoweredOn:
            return "BLECStatePoweredOn"
        case .Resetting:
            return "BLECStateResetting"

        case .Searching:
            return "BLECStateSearching"
        }
    }

    private func _appendLog(str: String) {
        if let ts = self.logView.textStorage {
            let attrStr = NSAttributedString(string: str + "\n")
            ts.appendAttributedString(attrStr)
        }
    }

    private func _showRSSI(RSSI: Int) {
        self.rssiLabel.integerValue = RSSI
    }

    func centralDidUpdateState(manager: BLECManager) {
        _appendLog(_stateName(_manager.state))
    }

    func central(manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {
        _appendLog("Discovered: \(peripheral.identifier.UUIDString)")
        _showRSSI(RSSI)
    }

    func central(central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {
        _appendLog("Connected \(peripheral.identifier.UUIDString)")
        _timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                        target: self,
                                                        selector: #selector(_update),
                                                        userInfo: nil,
                                                        repeats: true)
    }

    func central(central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {
        _device = device
    }

    func central(central: BLECManager, didDisconnectDevice device: BLECDevice, error: NSError?) {
        DLog("Disconnected");
        let uuid = device.peripheral?.identifier.UUIDString ?? ""
        _appendLog("Disconnected: \(uuid)")
        self.rssiLabel.stringValue = "0"
        if let timer = _timer {
            timer.invalidate()
            _timer = nil
        }
    }

    func device(device: BLECDevice, didReadRSSI RSSI: Int, error: NSError?) {
        if let error = error {
            DLog("error at RSSI reading: \(error)")
            return
        }

        _showRSSI(RSSI)
    }
}


//............................................................................
// MARK: - Data characteristic extension.
//............................................................................

extension ViewController: DataCharacteristicDelegate {

    func found() {
        _appendLog("Data characteristic found!")
    }

    func dataRead(dataSize: Int) {
        _dataSize += dataSize;
    }
}


//............................................................................
// MARK: - Control characteristic extension.
//............................................................................

extension ViewController: ControlCharacteristicDelegate {

    func controlUpdated(state: ButtonAction) {
        guard let characteristic = _device?.characteristicAt(1, inServiceAt: 0) else {
            return
        }
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Control characteristic updated!")
        })
        let data = NSData(bytes: [UInt8(1)], length: 1)
        do {
            try _device?.writeValue(data,
                                    forCharacteristic: characteristic,
                                    response: { (error) in
                dispatch_async(dispatch_get_main_queue(), {
                    self._appendLog("Start data write responded.")
                })
            })
        } catch BLECDevice.Error.AlredyPending {
            print("Unresponded write is in progress.")
        } catch BLECDevice.Error.InvalidCharacteristic {
            print("Characteristic is not maintained by BLECManager.")
        } catch BLECDevice.Error.NoPeripheral {
            print("Peripheral is not maintained by BLECManager.")
        } catch {
            assert(false, "Unknown error at write for characteristic.")
        }
    }
    
}


//............................................................................
// MARK: - Info characteristic extension.
//............................................................................

extension ViewController: InfoCharacteristicDelegate {

    func infoCharacteristicName(name: String, value: String) {
        _appendLog("\(name): \(value)")
    }
}
