
//
//  ViewController.m
//  AudioPlayerTemplate
//

//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//


#import "ViewController.h"

@interface ViewController () {
    NSString *ownUUID;
    NSString *trackId;
    NSString *dataPath;
    NSURL *dataPathURL;
    MBProgressHUD *progress;
    NSMutableArray *audioDatas;
    NSInteger PreviousTrackNumber;
    
    NSArray *paths;
    NSString *path;
    NSInteger totalNumber;
    NSInteger currentNumber;
    BOOL firstPlay;
    NSMutableArray *trackIDs;
    NSDictionary *trackhistory;
    NSMutableArray *trackHistorys;
    NSMutableArray *tracklastListen;
    NSMutableArray *trackisListen;
    int islistened;
    BOOL isNetWorking;
    BOOL isdDownloading;
    
    NSString *currentNumberHistory;
    NSString *totalNumberHistory;
    NSString *writefile ;
    NSInteger totalcacheSize;
    NSInteger limitSize;
    NSString *trackrecId;
    NSInteger trecId;
    NSString *fileDir;
    
}

@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) id timeObserver;
@end

@implementation ViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    firstPlay = true;
    totalNumber = 0;
    currentNumber = 0;
    totalcacheSize = 0;
    PreviousTrackNumber = 0;
    self.isPaused = TRUE;
    isNetWorking  = TRUE;
    self.isStoped = TRUE;
    isdDownloading  = FALSE;
    trackHistorys = [[NSMutableArray alloc] init];
    trackisListen = [[NSMutableArray alloc] init];
    tracklastListen = [[NSMutableArray alloc] init];
    trackIDs = [[NSMutableArray alloc] init];
    trackhistory = [[NSDictionary alloc] init];
    audioDatas = [[NSMutableArray alloc] init];
    self.player = [[AVQueuePlayer alloc] init];
    limitSize = 1024 * 1024 * 1024;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    ownUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; // IOS 6+
    NSLog(@"output is : %@", ownUUID);
    trecId = 0;
    
    self.lblTitle.text = @"Loading...";
    
    NSString *docDir;
    NSArray *dirPaths;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docDir = dirPaths[0];
    
    _databasePath = [[NSString alloc] initWithString: [docDir stringByAppendingPathComponent:@"historyDB.db"]];
    _historyPath = [[NSString alloc] initWithString: [docDir stringByAppendingPathComponent:@"history.txt"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_historyPath]){
        [[NSFileManager defaultManager] createFileAtPath:_historyPath contents:nil attributes:nil];
        writefile = [NSString stringWithFormat:@"%05ld:%05ld", totalNumber, currentNumber];
        [writefile writeToFile:_historyPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    writefile = [NSString stringWithContentsOfFile:_historyPath encoding:NSUTF8StringEncoding error:nil];
    totalNumberHistory = [writefile substringToIndex:5];
    currentNumberHistory = [writefile substringFromIndex:6];
    totalNumber = [totalNumberHistory integerValue];
    currentNumber = [currentNumberHistory integerValue];
    PreviousTrackNumber = currentNumber;
    currentNumber = 0;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_historyDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS HISTORYDB (ID INTEGER PRIMARY KEY AUTOINCREMENT, RECID TEXT, TRACKID TEXT, DATETIMELISTEN TEXT, ISLISTEN INTEGER)";
            
            if (sqlite3_exec(_historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
            }
            sqlite3_close(_historyDB);
        } else {
        }
    }
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    path = [paths  objectAtIndex:0];
    fileDir = path;
//    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if(progress == nil) {
        progress = [[MBProgressHUD alloc] initWithView:self.view];
    }
    [self.view addSubview:progress];
    progress.dimBackground = YES;
    progress.delegate = self;
    [progress show:YES];
    
    
    // Set AVAudioSession
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setDelegate:self];
    if(![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError]){
        
        NSLog(@"Audio Session error %@, %@", sessionError, [sessionError userInfo]);
    }else{
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    
    // Change the default output audio route
    UInt32 doChangeDefaultRoute = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkStateChanged:)
                                                 name:kReachabilityChangedNotification object:nil];
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self postTrackHistory:trackHistorys];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    NSArray *dir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileDir error:nil];
    [dir enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        NSString *extension = [[filename pathExtension] lowercaseString];
        if ([extension isEqualToString:@"mp3"]) {
            [audioDatas addObject:[fileDir stringByAppendingPathComponent:filename]];
        }
    }];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getfilePath:currentNumber]]) {
//        [self setupAudioPlayerwithURL:[self getAudioPathWithURL:currentNumber]];
        [self setupAudioPlayerwithURL:[NSURL fileURLWithPath:[audioDatas objectAtIndex:0]]];
        [progress hide:YES];
//    }
//    else{
    if ([audioDatas count] == 0) {
        [progress show:YES];
        if (!isdDownloading) {
            [self downloadAudiofileFromServer];
        }
    }
    
    totalcacheSize = [self getcacheSize];
    NetworkStatus currentNetStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (currentNetStatus == NotReachable) {
        // No Internet connection
        
        isNetWorking  = FALSE;
    } else {
        // We are back !
        if (!isNetWorking) {
            if (!isdDownloading) {
                [self downloadAudiofileFromServer];
            }
        }
        isNetWorking  = TRUE;
    }

}
-(NSInteger)getcacheSize{
    
    NSInteger sum = 0;
    for (int i = 0; i < [audioDatas count]; i++) {
        sum += [self getfileSize:[audioDatas objectAtIndex:i]];
    }
    if (sum < limitSize) {
        if (!isdDownloading) {
            [self downloadAudiofileFromServer];
        }
    }
    return sum;

}

- (NSInteger )getfileSize:(NSString*) tempfilePath{
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempfilePath error:nil];
    NSInteger filesize = (NSInteger )[fileAttributes fileSize];
    return filesize;
    
}

-(void) remoteControlReceivedWithEvent:(UIEvent *)event{
    if (event.type == UIEventTypeRemoteControl){
        switch(event.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self play];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                break;
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self next];
                break;
                
            default:
                break;
        }
    }
}
-(void) play{
    if (self.isStoped) {
        if(firstPlay){
            [self.player play];
            [self.playButton setBackgroundImage:[UIImage imageNamed:@"pause_button.png"]
                                       forState:UIControlStateNormal];
            
            self.isPaused = FALSE;
            self.isStoped = FALSE;
            firstPlay = FALSE;
        }else{
            
            [self next];
            
        }
    }
    else if (!self.isPaused) {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"play_button.png"]
                                   forState:UIControlStateNormal];
        
        self.isPaused = TRUE;
        self.isStoped = FALSE;
        [self.player pause];
    } else {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"pause_button.png"]
                                   forState:UIControlStateNormal];
        
        [self.player play];
        
        self.isPaused = FALSE;
        self.isStoped = FALSE;
    }
}
-(void) next{
    
    [trackisListen addObject:[NSString stringWithFormat:@"%@", self.duration.text]];
    [trackisListen addObject:@"-1"];
    int audiocount = (int)[audioDatas count];
    currentNumber  = (NSInteger)arc4random_uniform(audiocount);
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[audioDatas objectAtIndex:currentNumber]]];
    
    [self.player removeAllItems];
    if ([self.player canInsertItem:item afterItem:nil]) {
        [self.player insertItem:item afterItem: nil];
    }
    AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[audioDatas objectAtIndex:currentNumber]] options:nil];
    NSArray *metadata = [asset commonMetadata];
    for (AVMetadataItem *item in metadata) {
        if ([[item commonKey] isEqualToString:@"title"]) {
            self.lblTitle.text = (NSString*)[item value] ;
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEndItem:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    self.slider.maxValue = CMTimeGetSeconds([self.player currentItem].asset.duration);
    self.slider.rightValue = CMTimeGetSeconds([self.player currentItem].asset.duration);
    self.slider.leftValue = 0;
    self.slider.minValue = 0;
    //play audio for the first time or if pause was pressed
    [self.playButton setBackgroundImage:[UIImage imageNamed:@"pause_button.png"]
                               forState:UIControlStateNormal];
    self.isStoped = FALSE;
    self.isPaused = FALSE;
    
    totalcacheSize = [self getcacheSize];
    if (totalcacheSize < limitSize) {
        if (!isdDownloading) {
            [self downloadAudiofileFromServer];
        }
    }
    writefile = [NSString stringWithFormat:@"%05ld:%05ld", totalNumber , currentNumber];
    [writefile writeToFile:_historyPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self.player play];
    [self postTrackHistory:trackHistorys];

}
-(BOOL) canBecomeFirstResponder{
    return YES;
}
/*
 * Hide the statusbar
 */
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
- (void)viewWillAppear:(BOOL)animated{

}

/*
 * Download Audio File---
 */
-(BOOL) downloadAudiofileFromServer{
        isdDownloading = TRUE;
    [[RedmineAPI sharedManager] getTrackId:ownUUID onSucess:^(NSData *strdata) {
        
        if (strdata != nil) {
            NSLog(@"%@",strdata);
            NSString* dict = [[NSString alloc] initWithData:strdata encoding:NSUTF8StringEncoding];
            NSRange range = NSMakeRange(1, strdata.length - 2);
            trackId = [dict substringWithRange:range];
            [trackIDs addObject:trackId];
            NSLog(@"track_id = %@", trackId);
            [[RedmineAPI sharedManager] getAudio:trackId onSucess:^(NSData *json) {
                
                NSLog(@"%@", json);
                NSData *audioData = json;
                
                [self addAudioData:audioData];
            } onFailure:^(NSData *json) {
                
            }];
        }
        
    } onFailure:^(NSData* error) {
        
    }];

    return NO;
}
/*
 * POST track history
 */
-(void) postTrackHistory:(NSMutableArray*)tHistory{
    for (int i = 0; i < [tracklastListen count] ; i++) {
        
        [[RedmineAPI sharedManager] saveHistory:ownUUID track_id:[trackIDs objectAtIndex:i] lastListen:[tracklastListen objectAtIndex:i] isListen:[trackisListen objectAtIndex:i] method:@"random" onSuccess:^(NSData *json){
            
        }onFailure:^(NSData* json){
                                          
        }];
    }

}
/*
 * Add NSData to NSMutableArray
 */
- (void) addAudioData:(NSData*) aData{
    totalNumber ++;
    
    isdDownloading = FALSE;
    
    //Save the data
    
    dataPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"audio_%ld.mp3", totalNumber]];
    dataPath = [dataPath stringByStandardizingPath];
    BOOL success = [aData writeToFile:dataPath atomically:YES];
    [audioDatas addObject:dataPath];
    if (success) {
        NSLog(@"File Write Success");
    }
    else{
        NSLog(@"File Write Failed");
    }
    totalcacheSize = [self getcacheSize];
    if (totalcacheSize < limitSize) {
        if (!isdDownloading) {
            
            [self downloadAudiofileFromServer];
   
        }
    }
}

- (void)setupAudioPlayerwithURL:(NSURL*)fileNameURL
{
    //insert Filename & FileExtension
    //init the Player to get file properties to set the time labels
    NSArray *queue = @[ [AVPlayerItem playerItemWithURL:fileNameURL]];
    
    self.player = [[AVQueuePlayer alloc] initWithItems:queue];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEndItem:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [self.player addObserver:self
                  forKeyPath:@"currentItem"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    
    void (^observerBlock)(CMTime time) = ^(CMTime time) {
        AVPlayerItem *item = ((AVPlayer *)self.player).currentItem;
        self.timeElapsed.text = [NSString stringWithFormat:@"%d:%02d", (int)CMTimeGetSeconds(item.currentTime) / 60, (int)CMTimeGetSeconds(item.currentTime) % 60 ];
            
        self.duration.text = [NSString stringWithFormat:@"-%d:%02d", (int)( CMTimeGetSeconds(item.duration) - CMTimeGetSeconds(item.currentTime)) / 60, (int)( CMTimeGetSeconds(item.duration) - CMTimeGetSeconds(item.currentTime)) % 60 ];
        
        AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[audioDatas objectAtIndex:currentNumber]] options:nil];
        NSArray *metadata = [asset commonMetadata];
        for (AVMetadataItem *item in metadata) {
            if ([[item commonKey] isEqualToString:@"title"]) {
                self.lblTitle.text = (NSString*)[item value] ;
            }
            if ([[item commonKey] isEqualToString:@"image"]) {
                self.lblTitle.text = (NSString*)[item value] ;
            }
        }
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.lblTitle.text, MPMediaItemPropertyTitle, [NSNumber numberWithDouble:[self currentPlayBackDuration]], MPMediaItemPropertyPlaybackDuration,[NSNumber numberWithDouble:[self currentPlayBackTime]], MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
        self.slider.leftValue = CMTimeGetSeconds(item.currentTime);
        
    };
    
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(10, 1000)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:observerBlock];
    
    self.slider.maxValue = CMTimeGetSeconds([self.player currentItem].asset.duration);
    self.slider.rightValue = CMTimeGetSeconds([self.player currentItem].asset.duration);
    self.slider.leftValue = 0;
    self.slider.minValue = 0;
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:fileNameURL options:nil];
    NSArray *metadata = [asset commonMetadata];
    for (AVMetadataItem *item in metadata) {
        if ([[item commonKey] isEqualToString:@"title"]) {
            self.lblTitle.text = (NSString*)[item value] ;
        }
    }
    //init the current timedisplay and the labels. if a current time was stored
    //for this player then take it and update the time display
    self.timeElapsed.text = @"0:00";
    
    self.duration.text = [NSString stringWithFormat:@"-%d:%2d", (int)self.slider.maxValue / 60, (int)self.slider.maxValue % 60 ];
    
    [progress hide:YES];
    
}
- (NSTimeInterval)currentPlayBackTime{
    CMTime time = self.player.currentItem.currentTime;
    if (CMTIME_IS_VALID(time)) {
        return time.value / time.timescale;
    }
    return 0;
}
- (NSTimeInterval)currentPlayBackDuration{
    CMTime time = self.player.currentItem.duration;
    if (CMTIME_IS_VALID(time)) {
        return time.value / time.timescale;
    }
    return 0;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentItem"])
    {
        AVPlayerItem *item = ((AVPlayer *)object).currentItem;
        
        self.slider.leftValue = CMTimeGetSeconds(item.currentTime);

        self.timeElapsed.text = [NSString stringWithFormat:@"%d:%02d", (int)CMTimeGetSeconds(item.currentTime) / 60, (int)CMTimeGetSeconds(item.currentTime) % 60 ];
        
        self.duration.text = [NSString stringWithFormat:@"-%d:%02d", (int)( CMTimeGetSeconds(item.duration) - CMTimeGetSeconds(item.currentTime)) / 60, (int)( CMTimeGetSeconds(item.duration) - CMTimeGetSeconds(item.currentTime)) % 60 ];
        
        AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[audioDatas objectAtIndex:currentNumber]] options:nil];
        NSArray *metadata = [asset commonMetadata];
        for (AVMetadataItem *item in metadata) {
            if ([[item commonKey] isEqualToString:@"title"]) {
                self.lblTitle.text = (NSString*)[item value] ;
            }
        }
        NSLog(@"New music name: %@", self.lblTitle.text);
    }
}
/*
 * PlayButton is pressed
 * plays or pauses the audio and sets
 * the play/pause Text of the Button
 */
- (IBAction)nextAudioPressed:(id)sender {
    self.isStoped = TRUE;
    
    [self deleteoldTracks: [audioDatas objectAtIndex:currentNumber]];
    [audioDatas removeObjectAtIndex:currentNumber];
//    if (currentNumber < totalNumber) {
        [self nextTrack];
//    }
}

- (IBAction)playAudioPressed:(id)playButton
{
    [self play];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)playerEndItem:(NSNotification *)notification{
    self.isStoped = TRUE;
        [self next];
}
-(void)nextTrack{
    
    [self next];
}
- (void)networkStateChanged:(NSNotification *)notice {
    NetworkStatus currentNetStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (currentNetStatus == NotReachable) {
        // No Internet connection
        
        isNetWorking  = FALSE;
    } else {
        // We are back !
        
        isNetWorking  = TRUE;
        [self downloadAudiofileFromServer];
    }
}

-(void) deleteoldTracks:(NSString*)temppath{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyyy"];
    
    //Optionally for time zone conversions
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    
    [self saveData:trackId :stringFromDate :(int)trecId :[NSString stringWithFormat:@"%d",islistened]];
        NSFileManager * fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL fileExist = [fileManager fileExistsAtPath:temppath];
        if (fileExist) {
            BOOL success = [fileManager removeItemAtPath:temppath error:&error];
            if (!success) {
                NSLog(@"Error :%@", [error localizedDescription]);
            }
        }
}

- (void) saveData:(NSString *)tId_ :(NSString*)date_ :(int)islisten_:(NSString*)recid_
{
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_historyDB) == SQLITE_OK)
    {
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO HISTORY (recid, trackid, datetimelisten, islisten) VALUES (\"%@\", \"%@\", \"%@\", \"%d\")",
                               recid_,tId_, date_, islisten_];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_historyDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Success to add:");
        } else {
            NSLog(@"Error: %@",@"Failed to add contact");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_historyDB);
    }
}

- (void) findData:(NSString*)recid_
{
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_historyDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"SELECT tracid, datetimelisten, islisten FROM historydb WHERE recid=\"%@\"",
                              [NSString stringWithFormat:@"%@",recid_]];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_historyDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                [trackIDs addObject: [[NSString alloc]
                                      initWithUTF8String:
                                      (const char *) sqlite3_column_text(
                                                                         statement, 0)]];
                [trackisListen addObject: [[NSString alloc]
                                      initWithUTF8String:
                                      (const char *) sqlite3_column_text(
                                                                         statement, 1)]];
                [trackHistorys addObject: [[NSString alloc]
                                      initWithUTF8String:
                                      (const char *) sqlite3_column_text(
                                                                         statement, 2)]];

            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_historyDB);
    }
}
@end
