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

#import "AFBMHTTPRequestOperationManager.h"
#import "UAObfuscatedString.h"

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
        DLog(@"Start BMSDK");
    }
    return self;
}

-(void)start
{
    [Flurry startSession:Obfuscate.P.Q.K.M._6.J.Q.Y._9.Z._9.G.N.P._6.Z.M.P.B._4];
    _locationManager = [BMLocationManager sharedInstance];
    
    _statsManager = [BMUsageStatisticManager sharedInstance];
}

/**
 Handles the notification for BlueMate notifications type (Area/Modal/Background)
 @param userInfo The notification dictionary
 @return The notification minus the objectForKey used
 */
-(NSDictionary *)handleNotification:(NSDictionary *)userInfo
{
    if ([userInfo objectForKey:@"b"]) {
        DLog(@"Found push notification for Background Notification Usage");
        DLog(@"B Content: %@", [userInfo description]);
        
    }
    else if ([userInfo objectForKey:@"m"])
    {
        DLog(@"Found push notification for ModalView Notification Usage");
        DLog(@"M Content: %@", [userInfo description]);
    }
    else if ([userInfo objectForKey:@"a"])
    {
        DLog(@"Found push notification for Area Notification Usage");
        //Save data inside NSUserDefaults
        DLog(@"A Content: %@", [userInfo description]);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[userInfo objectForKey:@"hi"] forKey:@"welcomeMessage"];
        [userDefaults setObject:[userInfo objectForKey:@"bye"] forKey:@"goodbyeMessage"];
        [userDefaults synchronize];
    }
    
    return userInfo;
}

@end
