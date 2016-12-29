//
//  ViewController.swift
//  Peripheral_Example
//
//  Created by Balázs Kilvády on 6/23/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import Cocoa

protocol PeripheralDelegate: class {
    func logMessage(_ message: String)
    func central(_ central: String, didSubscribeToCharacteristic characteristic: String)
    func central(_ central: String, didUnsubscribeFromCharacteristic characteristic: String)
    func sending(_ toggle: Bool)
}

class ViewController: NSViewController {

    @IBOutlet var logView: NSTextView!

    fileprivate var _peripheral: Peripheral!
    fileprivate let _sampleData = "01234567890123456789".data(using: String.Encoding.ascii)!
    fileprivate let _kRepeatCount: UInt = 640
    fileprivate var _timer: Timer?
    fileprivate var _isSubscribed = false
    fileprivate var _isSending = false


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _peripheral = Peripheral(delegate: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func timerFired() {
        _peripheral.sendToSubscribers(_sampleData, repeatCount: _kRepeatCount)
    }

    fileprivate func _toggleTimer() {
        if _isSubscribed && _isSending {
            if _timer == nil {
                DLog("start timer.")
                _timer = Timer.scheduledTimer(timeInterval: 1.0,
                                              target: self,
                                              selector: #selector(timerFired),
                                              userInfo: nil,
                                              repeats: true)
                _timer?.fire()
            }
        } else {
            if let timer = _timer {
                DLog("stop timer.")
                timer.invalidate()
                _timer = nil
            }
        }
    }
}


extension ViewController: PeripheralDelegate {

    func logMessage(_ message: String) {
        let msg = message + "\n"
        logView.textStorage?.append(NSAttributedString(string: msg))
    }

    func central(_ central: String, didSubscribeToCharacteristic characteristic: String) {
        logMessage("subscribed central: \(central) for \(characteristic)")
        _isSubscribed = true
        _toggleTimer()
    }

    func central(_ central: String, didUnsubscribeFromCharacteristic characteristic: String) {
        logMessage("unsubscribed central: \(central) for \(characteristic)")
        _isSubscribed = false
        _toggleTimer()
    }

    func sending(_ toggle: Bool) {
        logMessage("sending toggled: " + (toggle ? "true" : "false"))
        _isSending = toggle
        _toggleTimer()
    }
}
