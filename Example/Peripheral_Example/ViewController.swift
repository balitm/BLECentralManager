//
//  ViewController.swift
//  Peripheral_Example
//
//  Created by Balázs Kilvády on 6/23/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import Cocoa

protocol PeripheralDelegate: class {
    func logMessage(message: String)
    func central(central: String, didSubscribeToCharacteristic characteristic: String)
    func central(central: String, didUnsubscribeFromCharacteristic characteristic: String)
}

class ViewController: NSViewController {

    @IBOutlet var logView: NSTextView!

    private var _peripheral: Peripheral!
    private let _sampleData = "01234567890123456789".dataUsingEncoding(NSASCIIStringEncoding)!
    private let _kRepeatCount: UInt = 640
    private var _timer: NSTimer?


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _peripheral = Peripheral(delegate: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func timerFired() {
        _peripheral.sendToSubscribers(_sampleData, repeatCount: _kRepeatCount)
    }
}


extension ViewController: PeripheralDelegate {

    func logMessage(message: String) {
        let msg = message + "\n"
        logView.textStorage?.appendAttributedString(NSAttributedString(string: msg))
    }

    func central(central: String, didSubscribeToCharacteristic characteristic: String) {
        logMessage("subscribed central: \(central) for \(characteristic)")
        if _timer == nil {
            DLog("start timer.")
            _timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
            _timer!.fire()
        }
    }

    func central(central: String, didUnsubscribeFromCharacteristic characteristic: String) {
        logMessage("unsubscribed central: \(central) for \(characteristic)")
        if _peripheral.subscribersCount == 0 {
            if let timer = _timer {
                DLog("stop timer.")
                timer.invalidate()
                _timer = nil
            }
        }
    }
}
