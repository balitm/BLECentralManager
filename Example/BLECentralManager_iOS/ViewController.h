//
//  ViewController.h
//  BLECentralManager
//
//  Created by Balázs Kilvády on 05/18/2016.
//  Copyright (c) 2016 Balázs Kilvády. All rights reserved.
//

@import UIKit;

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@end
