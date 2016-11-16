//
//  ViewController.h
//  AudioPlayerTemplate

//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ownSlider.h"
#import "RedmineAPI.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <sqlite3.h>
@interface ViewController : UIViewController

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *historyDB;
@property (strong, nonatomic) NSString *historyPath;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsed;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic) IBOutlet ownSlider *slider;

@property BOOL isPaused;
@property BOOL isStoped;

@property NSTimer *timer;

@end
