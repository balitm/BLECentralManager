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

    fileprivate static let _kMaxKbps: Float = 1024.0 * 100.0

    fileprivate var _manager: BLECManager!
    fileprivate var _timer: Timer?
    fileprivate var _dataSize: Int = 0
    fileprivate weak var _device: BLECDevice?
    fileprivate var _buttonState = ButtonAction.start {
        didSet {
            switch _buttonState {
            case .stop:
                startButton.setTitle("Stop", for: .normal)
                progressView.progress = Float(0)
            case .start:
                startButton.setTitle("Start", for: .normal)
            }
        }
    }

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet var logView: UITextView!
    @IBOutlet weak var startButton: UIButton!


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

        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
        _manager = BLECManager(config: config, queue: queue)
        _manager.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //---- logView workaround at resize/rotatation ----
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        logView.isScrollEnabled = false
        logView.isScrollEnabled = true
    }

    @IBAction func actionStart(_ sender: UIButton) {
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
            try _device?.writeValue(data, forCharacteristic: characteristic, response: { (error) in
                DispatchQueue.main.async(execute: {
                    self._appendLog("\(array[0] == 1 ? "Start" : "Stop") data write responded.")
                })
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
        //---- compute speed & progress ----
        let bitSize = Float(_dataSize) * 8.0
        self.progressView.setProgress(bitSize / ViewController._kMaxKbps, animated: true)
        let numString = String(format: "%0.2f", bitSize / Float(1024.0))
        self.speedLabel.text = numString
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
        if let text = self.logView.text {
            self.logView.text = text + str + "\n"
        }
    }

    fileprivate func _showRSSI(_ RSSI: Int) {
        self.rssiLabel.text = String(RSSI)
    }

    fileprivate func _zeroViews() {
        _showRSSI(0)
        progressView.progress = 0.0
        speedLabel.text = "0"
    }

    func centralDidUpdateState(_ manager: BLECManager) {
        DispatchQueue.main.async { [unowned self] in
            self._appendLog(self._stateName(self._manager.state))
        }
    }

    func central(_ manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {
        DispatchQueue.main.async { [unowned self] in
            self._appendLog("Discovered: \(peripheral.identifier.uuidString)")
            self._showRSSI(RSSI)
        }
    }

    func central(_ central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {
        DispatchQueue.main.async { [unowned self] in
            self._appendLog("Connected \(peripheral.identifier.uuidString)")
            self._timer = Timer.scheduledTimer(
                timeInterval: 1.0,
                target: self,
                selector: #selector(self._update),
                userInfo: nil,
                repeats: true)
        }
    }

    func central(_ central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {
        _device = device
    }

    func central(_ central: BLECManager, didDisconnectDevice device: BLECDevice, error: Error?) {
        DLog("Disconnected")
        let uuid = device.UUID.uuidString

        DispatchQueue.main.async { [unowned self] in
            self._appendLog("Disconnected: \(uuid)")
            self._zeroViews()
            self.startButton.isEnabled = false
            self._device = nil
            if let timer = self._timer {
                timer.invalidate()
                self._timer = nil
            }
        }
    }

    func device(_ device: BLECDevice, didReadRSSI RSSI: Int, error: Error?) {
        if let error = error {
            DLog("error at RSSI reading: \(error)")
            return
        }
        
        DispatchQueue.main.async { [unowned self] in
            self._showRSSI(RSSI)
        }
    }

}


//............................................................................
// MARK: - Data characteristic extension.
//............................................................................

extension ViewController: DataCharacteristicDelegate {
    
    func dataFound() {
        DispatchQueue.main.async {
            self._appendLog("Data characteristic found!")
        }
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
        DispatchQueue.main.async { [unowned self] in
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
        DispatchQueue.main.async { [unowned self] in
            self._appendLog("\(name): \(value)")
        }
    }
}
