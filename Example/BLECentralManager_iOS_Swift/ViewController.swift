//
//  ViewController.swift
//  BLECentralManager_iOS_Swift
//
//  Created by Balázs Kilvády on 6/30/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import UIKit
import CoreBluetooth
import BLECentralManager


class ViewController: UIViewController {

    private static let _kMaxKbps: Float = 1024.0 * 100.0

    private var _manager: BLECManager!
    private var _timer: NSTimer?
    private var _dataSize: Int = 0
    private var _device: BLECDevice?

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet var logView: UITextView!


    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let dataChar = DataCharacteristic()
        dataChar.delegate = self;

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
                        delegate: dataChar)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func _update() {
        //---- compute progress ----
        self.progressView.setProgress(Float(_dataSize) / (ViewController._kMaxKbps / 8.0), animated: true)
        _dataSize = 0

        //---- read RSSI ----
        _device?.readRSSI()
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
        if let text = self.logView.text {
            self.logView.text = text + str + "\n"
        }
    }

    private func _showRSSI(RSSI: Int) {
        self.rssiLabel.text = String(RSSI)
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
        _showRSSI(0)
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
// MARK: - Info characteristic extension.
//............................................................................

extension ViewController: InfoCharacteristicDelegate {
    
    func infoCharacteristicName(name: String, value: String) {
        _appendLog("\(name): \(value)")
    }
}
