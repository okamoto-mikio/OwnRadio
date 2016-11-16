//
//  RedmineAPI.m
//  BestDoctorsClub
//
//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//
//

#import "RedmineAPI.h"

@implementation RedmineAPI

+ (RedmineAPI *)sharedManager {
    static RedmineAPI *sharedManager = nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedManager = [RedmineAPI manager];
        [sharedManager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
        
    });
    return sharedManager;
}

- (void)getTrackId:(NSString*) deviceuuid onSucess:(SuccessBlock)completionBlock onFailure:(FailureBlock)failureBlock
{
    
    NSString *url = [NSString stringWithFormat:@"%@%@/next", OwnAudioApiBaseUrl, deviceuuid];
    [self GET:url parameters:nil onSuccess:completionBlock onFailure:failureBlock];
}

- (void)getAudio:(NSString*) trackid  onSucess: (SuccessBlock)completionBlock onFailure:(FailureBlock)failureBlock
{
    NSString *url = [NSString stringWithFormat:@"%@%@", OwnAudioApiBaseUrl, trackid];
    [self GET:url parameters:nil onSuccess:completionBlock onFailure:failureBlock];

}
- (void)saveHistory:(NSString *)deviceid track_id:(NSString *)track_id lastListen :(NSString *)lastListen  isListen :(NSString *)isListen  method:(NSString *)method onSuccess:(SuccessBlock)completionBlock onFailure:(FailureBlock)failureBlock
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"lastListen":lastListen
                                                                                      , @"isListen":isListen
                                                                                      , @"method":method}];
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", OwnAudioApiBaseUrl, deviceid, track_id];
    [self POST:url parameters:parameters onSuccess:completionBlock onFailure:failureBlock];
}


- (void)GET:(NSString *)url
  parameters:(NSMutableDictionary*)parameters
   onSuccess:(SuccessBlock)completionBlock
   onFailure:(FailureBlock)failureBlock
{
    // Check out network connection
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"There IS NO internet connection");
//        [SHAlertHelper showOkAlertWithTitle:@"Error" message:@"We are unable to connect to our servers.\rPlease check your connection."];
        
        failureBlock(nil);
        return;
    }
//    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"GET url : %@", url);
    NSLog(@"GET param : %@", parameters);
    
    [self GET:url parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        NSData* data = (NSData*)responseObject;
//        NSString* dict = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"GET success : %@", data);
        completionBlock(data);
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"GET Error  %@", error);
//        [SHAlertHelper showOkAlertWithTitle:@"Connection Error" andMessage:@"Error occurs while connecting to web-service. Please try again!" andOkBlock:nil];
        failureBlock(nil);
    }];
}
- (void)POST:(NSString *)url
  parameters:(NSMutableDictionary*)parameters
   onSuccess:(SuccessBlock)completionBlock
   onFailure:(FailureBlock)failureBlock
{
    // Check out network connection
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"There IS NO internet connection");
//        [SHAlertHelper showOkAlertWithTitle:@"Error" message:@"We are unable to connect to our servers.\rPlease check your connection."];
        failureBlock(nil);
        return;
    }
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    
    NSLog(@"POST url : %@", url);
    NSLog(@"POST param : %@", parameters);
    
    
    [self POST:url parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSData* data = (NSData*)responseObject;
        NSError* error = nil;
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        NSLog(@"POST success : %@", dict);
        completionBlock(data);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"POST Error  %@", error);
//        [SHAlertHelper showOkAlertWithTitle:@"Connection Error" andMessage:@"Error occurs while connecting to web-service. Please try again!" andOkBlock:nil];
        failureBlock(nil);
    }];
}


@end
