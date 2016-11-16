//
//  RedmineAPI.h
//  BestDoctorsClub
//
//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"

#import "Reachability.h"
#import "SHAlertHelper.h"
//-----------------

#define OwnAudioApiBaseUrl              @"http://java.ownradio.ru/api/v2/tracks/"



//-----------------

typedef void (^SuccessBlock)(NSData* strdata);
typedef void (^FailureBlock)(NSData* strdata);
typedef void (^Success)(id json);
typedef void (^Failure)(id json);

@interface RedmineAPI : AFHTTPRequestOperationManager;

+ (RedmineAPI *)sharedManager;


- (void)getTrackId:(NSString*) deviceuuid onSucess: (SuccessBlock)completionBlock
       onFailure:(FailureBlock)failureBlock;

- (void)getAudio:(NSString*) trackid onSucess: (SuccessBlock)completionBlock
          onFailure:(FailureBlock)failureBlock;

- (void)saveHistory:(NSString *)deviceid track_id:(NSString *)track_id lastListen :(NSString *)lastListen  isListen :(NSString *)isListen  method:(NSString *)method onSuccess:(SuccessBlock)completionBlock onFailure:(FailureBlock)failureBlock;

@end
