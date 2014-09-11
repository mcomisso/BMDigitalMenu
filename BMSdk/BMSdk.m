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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    _locationManager = [BMLocationManager sharedInstance];
    _statsManager = [BMUsageStatisticManager sharedInstance];
}

@end
