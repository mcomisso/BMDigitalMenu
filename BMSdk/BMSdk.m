//
//  BMSdk.m
//  BMSdk
//
//  Created by Matteo Comisso on 17/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMSdk.h"
#import "BMLocationManager.h"
#import "BMUsageStatisticManager.h"

#import "Flurry.h"

@interface BMSdk()

@property (nonatomic, strong) BMLocationManager *locationManager;
@property (nonatomic, strong) BMUsageStatisticManager *statsManager;

@end

@implementation BMSdk

-(id)init
{
    self = [super init];
    if (self) {
        //Initialization
        NSLog(@"Start BMSDK");
    }
    return self;
}

-(void)start
{
    [Flurry startSession:@"PQKM6JQY9Z9GNP6ZMPB4"];
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    _locationManager = [BMLocationManager sharedInstance];
    _statsManager = [BMUsageStatisticManager sharedInstance];
}

/**
 Handles the notification for BlueMate notifications type (Area/Modal/Background)
 @param userInfo The notification dictionary
 @return The notification minus the objectForKey used
 */
-(NSDictionary *)handleNotificationOrReturn:(NSDictionary *)userInfo
{
    if ([userInfo objectForKey:@"b"]) {
        NSLog(@"Found push notification for Background Notification Usage");
    }
    else if ([userInfo objectForKey:@"m"])
    {
        NSLog(@"Found push notification for ModalView Notification Usage");
    }
    else if ([userInfo objectForKey:@"a"])
    {
        NSLog(@"Found push notification for Area Notification Usage");
    }
    
    return userInfo;
}

@end
