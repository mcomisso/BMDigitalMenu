//
//  BMActivator.m
//  BMSdk
//
//  Created by Matteo Comisso on 27/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMActivator.h"
#import "BMLocationManager.h"

@implementation BMActivator

-(BOOL)canStartMenu
{
    BMLocationManager *locationManager = [BMLocationManager sharedInstance];
    
    return locationManager.canStartInterface;
}
@end
