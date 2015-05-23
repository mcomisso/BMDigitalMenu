//
//  BMSdk.m
//  BMSdk
//
//  Created by Matteo Comisso on 17/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMSdk.h"
#import "BMLocationManager.h"

#import "AFBMHTTPRequestOperationManager.h"
#import "UAObfuscatedString.h"

#import "Flurry.h"

@interface BMSdk()

@property (nonatomic, strong) BMLocationManager *locationManager;

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
    // Set here the session key of Flurry
    [Flurry startSession:Obfuscate.s.e.s.s.i.o.n.k.e.y];
    _locationManager = [BMLocationManager sharedInstance];
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
