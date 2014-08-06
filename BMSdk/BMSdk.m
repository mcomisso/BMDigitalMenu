//
//  BMSdk.m
//  BMSdk
//
//  Created by Matteo Comisso on 17/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMSdk.h"
#import "BMLocationManager.h"
#import "BMDownloadManager.h"

@interface BMSdk()

@property (nonatomic, strong) BMLocationManager *locationManager;

@end

@implementation BMSdk

-(id)init
{
    self = [super init];
    if (self) {
        //Initialization
        NSLog(@"Start BMSDK");
        _locationManager = [BMLocationManager sharedInstance];
    }
    return self;
}

@end
