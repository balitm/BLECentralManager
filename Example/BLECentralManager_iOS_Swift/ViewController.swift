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
    private weak var _device: BLECDevice?
    private var _buttonState = ButtonAction.Start {
        didSet {
            switch _buttonState {
            case .Stop:
                startButton.setTitle("Stop", forState: .Normal)
                progressView.progress = Float(0)
            case .Start:
                startButton.setTitle("Start", forState: .Normal)
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

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        _manager = BLECManager(config: config, queue: queue)
        _manager.delegate = self;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //---- logView workaround at resize/rotatation ----
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        logView.scrollEnabled = false
        logView.scrollEnabled = true
    }

    @IBAction func actionStart(sender: UIButton) {
        guard let characteristic = _device?.characteristicAt(1, inServiceAt: 0) else {
            return
        }

        var array: [UInt8] = [0]

        switch _buttonState {
        case .Start:
            array[0] = UInt8(1)
            _buttonState = .Stop
        case .Stop:
            array[0] = UInt8(0)
            _buttonState = .Start
        }
        let data = NSData(bytes: array, length: 1)
        do {
            try _device?.writeValue(data, forCharacteristic: characteristic, response: { (error) in
                dispatch_async(dispatch_get_main_queue(), {
                    self._appendLog("\(array[0] == 1 ? "Start" : "Stop") data write responded.")
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

    @objc private func _update() {
        //---- compute speed & progress ----
        let bitSize = Float(_dataSize) * 8.0
        self.progressView.setProgress(bitSize / ViewController._kMaxKbps, animated: true)
        let numString = String(format: "%0.2f", bitSize / Float(1024.0))
        self.speedLabel.text = numString
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
        if let text = self.logView.text {
            self.logView.text = text + str + "\n"
        }
    }

    private func _showRSSI(RSSI: Int) {
        self.rssiLabel.text = String(RSSI)
    }

    private func _zeroViews() {
        _showRSSI(0)
        progressView.progress = 0.0
        speedLabel.text = "0"
    }

    func centralDidUpdateState(manager: BLECManager) {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog(self._stateName(self._manager.state))
        })
    }

    func central(manager: BLECManager, didDiscoverPeripheral peripheral: CBPeripheral, RSSI: Int) {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Discovered: \(peripheral.identifier.UUIDString)")
            self._showRSSI(RSSI)
        })
    }

    func central(central: BLECManager, didConnectPeripheral peripheral: CBPeripheral) {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Connected \(peripheral.identifier.UUIDString)")
            self._timer = NSTimer.scheduledTimerWithTimeInterval(
                1.0,
                target: self,
                selector: #selector(self._update),
                userInfo: nil,
                repeats: true)
        })
    }

    func central(central: BLECManager, didCheckCharacteristicsDevice device: BLECDevice) {
        _device = device
    }

    func central(central: BLECManager, didDisconnectDevice device: BLECDevice, error: NSError?) {
        DLog("Disconnected");
        let uuid = device.UUID.UUIDString

        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Disconnected: \(uuid)")
            self._zeroViews()
            self._device = nil
            if let timer = self._timer {
                timer.invalidate()
                self._timer = nil
            }
        })
    }

    func device(device: BLECDevice, didReadRSSI RSSI: Int, error: NSError?) {
        if let error = error {
            DLog("error at RSSI reading: \(error)")
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self._showRSSI(RSSI)
        })
    }

}


//............................................................................
// MARK: - Data characteristic extension.
//............................................................................

extension ViewController: DataCharacteristicDelegate {
    
    func dataFound() {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Data characteristic found!")
        })
    }
    
    func dataRead(dataSize: Int) {
        _dataSize += dataSize;
    }

}


//............................................................................
// MARK: - Control characteristic extension.
//............................................................................

extension ViewController: ControlCharacteristicDelegate {

    func controlDidUpdate(state: ButtonAction) {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("Control characteristic updated!")
            self.startButton.enabled = true
            self._buttonState = state
        })
    }

}


//............................................................................
// MARK: - Info characteristic extension.
//............................................................................

extension ViewController: InfoCharacteristicDelegate {
    
    func infoCharacteristicName(name: String, value: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self._appendLog("\(name): \(value)")
        })
    }

}
