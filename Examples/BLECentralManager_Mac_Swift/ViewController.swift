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

    fileprivate static let _kMaxKbps = 1024.0 * 100.0

    fileprivate var _manager: BLECManager!
    fileprivate var _timer: Timer?
    fileprivate var _dataSize: Int = 0
    fileprivate var _device: BLECDevice?
    fileprivate var _buttonState = ButtonAction.start {
        didSet {
            switch _buttonState {
            case .stop:
                startButton.title = "Stop"
                progressView.doubleValue = 0.0
            case .start:
                startButton.title = "Start"
            }
        }
    }

    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var rssiLabel: NSTextField!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet var logView: NSTextView!
    @IBOutlet weak var startButton: NSButton!


    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let dataChar = DataCharacteristic()
        dataChar.delegate = self

        let controlChar = ControlCharacteristic()
        controlChar.delegate = self

        var infoChars = [
            InfoCharacteristic(name: "Manufacturer"),
            InfoCharacteristic(name: "Firmware"),
            InfoCharacteristic(name: "HwRev"),
            InfoCharacteristic(name: "SwRev")
        ]
        for i in infoChars.indices.suffix(from: 0) { infoChars[i].delegate = self }

        let config = BLECConfig(type: .onePheriperal, services: [
            BLECServiceConfig(
                type: [.advertised, .required],
                UUID: "965F6F06-2198-4F4F-A333-4C5E0F238EB7",
                characteristics: [
                    BLECCharacteristicConfig(
                        type: .required,
                        UUID: "89E63F02-9932-4DF1-91C7-A574C880EFBF",
                        delegate: dataChar),
                    BLECCharacteristicConfig(
                        type: .optional,
                        UUID: "88359D38-DEA0-4FA4-9DD2-0A47E2B794BE",
                        delegate: controlChar)
                ]),
            BLECServiceConfig(type: .optional,
                UUID: "180a",
                characteristics: [
                    // Manufacturer Name String characteristic.
                    BLECCharacteristicConfig(
                        type: .required,
                        UUID: "2a29",
                        delegate: infoChars[0]),

                    // board
                    BLECCharacteristicConfig(
                        type: .optional,
                        UUID: "2a26",
                        delegate: infoChars[1]),

                    // HwRev
                    BLECCharacteristicConfig(
                        type: .optional,
                        UUID: "2a27",
                        delegate: infoChars[2]),

                    // SwRev
                    BLECCharacteristicConfig(
                        type: .optional,
                        UUID: "2a28",
                        delegate: infoChars[3])
                ])
            ])

        _manager = BLECManager(config: config, queue: nil)
        _manager.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func actionStart(_ sender: NSButton) {
        guard let characteristic = _device?.characteristicAt(1, inServiceAt: 0) else {
            return
        }

        var array: [UInt8] = [0]

        switch _buttonState {
        case .start:
            array[0] = UInt8(1)
            _buttonState = .stop
        case .stop:
            array[0] = UInt8(0)
            _buttonState = .start
        }
        let data = Data(bytes: UnsafePointer<UInt8>(array), count: 1)
        do {
            try _device?.writeValue(data, forCharacteristic: characteristic, response: { error in
                DispatchQueue.main.async {
                    self._appendLog("\(array[0] == 1 ? "Start" : "Stop") data write responded.")
                }
            })
        } catch BLECDevice.DeviceError.alredyPending {
            DLog("Unresponded write is in progress.")
        } catch BLECDevice.DeviceError.invalidCharacteristic {
            DLog("Characteristic is not maintained by BLECManager.")
        } catch BLECDevice.DeviceError.noPeripheral {
            DLog("Peripheral is not maintained by BLECManager.")
        } catch {
            fatalError("Unknown error at write for characteristic.")
        }
    }
    
    @objc fileprivate func _update() {
        //---- compute speed ----
        let bitSize = Double(_dataSize) * 8.0
        self.progressView.doubleValue = bitSize / Double(ViewController._kMaxKbps)
        let numString = String(format: "%0.2f", bitSize / 1024.0)
        self.speedLabel.stringValue = numString
        _dataSize = 0

        //---- read RSSI ----
        do {
            try _device?.readRSSI()
        } catch BLECDevice.DeviceError.invalidCharacteristic {
            print("Characteristic is not maintained by BLECManager.")
        } catch BLECDevice.DeviceError.noPeripheral {
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

    fileprivate func _stateName(_ state: BLECentralState) -> String {
        switch (state) {
        case .initial:
            return "BLECStateInit"
        case .unknown:
            return "BLECStateUnknown"
        case .unsupported:
            return "BLECStateUnsupported"
        case .unauthorized:
            return "BLECStateUnauthorized"
        case .poweredOff:
            return "BLECStatePoweredOff"
        case .poweredOn:
            return "BLECStatePoweredOn"
        case .resetting:
            return "BLECStateResetting"

        case .searching:
            return "BLECStateSearching"
        }
    }

    fileprivate func _appendLog(_ str: String) {
        if let ts = self.logView.textStorage {
            let attrStr = NSAttributedString(string: str + "\n")
            ts.append(attrStr)
        }
    }

    fileprivate func _showRSSI(_ RSSI: Int) {
        self.rssiLabel.integerValue = RSSI
    }

    fileprivate func _zeroViews() {
        _showRSSI(0)
        progressView.doubleValue = 0.0
        speedLabel.stringValue = "0"
    }

    func centralDidUpdateState(_ manager: BLECManager) {
        _appendLog(_stateName(_manager.state))
    }

    func central(_ manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {
        _appendLog("Discovered: \(peripheral.identifier.uuidString)")
        _showRSSI(RSSI)
    }

    func central(_ central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {
        _appendLog("Connected \(peripheral.identifier.uuidString)")
        _timer = Timer.scheduledTimer(timeInterval: 1.0,
                                      target: self,
                                      selector: #selector(_update),
                                      userInfo: nil,
                                      repeats: true)
    }

    func central(_ central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {
        _device = device
    }

    func central(_ central: BLECManager, didDisconnectDevice device: BLECDevice, error: Error?) {
        DLog("Disconnected")
        let uuid = device.peripheral?.identifier.uuidString ?? ""
        _appendLog("Disconnected: \(uuid)")
        _zeroViews()
        startButton.isEnabled = false
        _device = nil
        if let timer = _timer {
            timer.invalidate()
            _timer = nil
        }
    }

    func device(_ device: BLECDevice, didReadRSSI RSSI: Int, error: Error?) {
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

    func dataRead(_ dataSize: Int) {
        _dataSize += dataSize
    }
}


//............................................................................
// MARK: - Control characteristic extension.
//............................................................................

extension ViewController: ControlCharacteristicDelegate {

    func controlDidUpdate(_ state: ButtonAction) {
        DispatchQueue.main.async {
            self._appendLog("Control characteristic updated!")
            self.startButton.isEnabled = true
            self._buttonState = state
        }
    }
}


//............................................................................
// MARK: - Info characteristic extension.
//............................................................................

extension ViewController: InfoCharacteristicDelegate {

    func infoCharacteristicName(_ name: String, value: String) {
        _appendLog("\(name): \(value)")
    }
}
