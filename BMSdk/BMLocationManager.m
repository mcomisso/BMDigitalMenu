//
//  BMLocationManager.m
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//

#import "BMLocationManager.h"
#import "BMDownloadManager.h"
#define BMBEACON @"66666666-6666-6666-6666-666666666666"

@import UIKit;

@interface BMLocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *bmBeaconRegion;
@property (nonatomic, strong) NSUUID *BMUUID;
@property (nonatomic, strong) CLBeacon *closestBeacon;

@property (nonatomic, strong) BMDownloadManager *downloadManager;

@property BOOL trackLocationNotified;
@property (nonatomic)  BOOL canTrackLocation;
@property BOOL setupCompleted;
@property BOOL bluetoothEnabled;

@end

@implementation BMLocationManager

#pragma mark - Class Methods
+(BMLocationManager *)sharedInstance
{
    static BMLocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}

/*
 Inizializzazione componenti essenziali
 -> settings manager (riutilizzabile in caso di problemi hardware e/o)
 ->
 */
-(id)initUniqueInstance
{
    self = [super init];
    if (self) {
        NSLog(@"Initialization BMSdk");
        
        self.trackLocationNotified = NO;
        self.setupCompleted = NO;
        self.closestBeacon = [[CLBeacon alloc]init];
        self.BMUUID = [[NSUUID alloc]initWithUUIDString:BMBEACON];
        
        //Download Manager
        self.downloadManager = [BMDownloadManager sharedInstance];
        
        [self setupManager];
        
        self.dispatchGroup = dispatch_group_create();
    }
    return self;
}


#pragma mark - Check availability and setup
-(BOOL)canTrackLocation
{
#if TARGET_IPHONE_SIMULATOR
// return YES;
#endif
    NSString *errorMessage;
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Beacon Tracking Unavailable");
    }
    
    if (![CLLocationManager locationServicesEnabled]) {
        errorMessage = @"locationServices Not enabled";
    }
    else
    {
        if (![CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
            errorMessage = @"Location Tracking not Available";
        }
        else
        {
            return YES;
        }
    }
    if (!self.trackLocationNotified) {
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.alertBody = errorMessage;
        [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
        self.trackLocationNotified = YES;
    }
    
    NSLog(@"%@", errorMessage);
    return NO;
    
}

-(void)setupManager
{
    if (!self.canTrackLocation || self.setupCompleted) {
        return;
    }
    
    self.bluetoothEnabled = YES;
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
    
    self.bmBeaconRegion = [[CLBeaconRegion alloc]initWithProximityUUID:self.BMUUID identifier:@"com.bluemate.mssdk"];
    
    [self.locationManager stopMonitoringForRegion:self.bmBeaconRegion];
    [self.locationManager startMonitoringForRegion:self.bmBeaconRegion];
    [self.locationManager requestStateForRegion:self.bmBeaconRegion];
    
    [self.locationManager startUpdatingLocation];
    
    self.setupCompleted = YES;
    
    [self startRanging];
}

#pragma mark - Shortcut methods
-(void)startRanging
{
    [self.locationManager startRangingBeaconsInRegion:self.bmBeaconRegion];
    NSLog(@"App startRanging");
}

-(void)stopRanging
{
    NSLog(@"App stopRanging");
}

-(void)enterBackground
{
    NSLog(@"App enters in background");
}

-(void)enterForeground
{
    NSLog(@"App enters in foreground");
}

#pragma mark - BMLocation Manager Delegate Methods
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString *authStatus = [[NSString alloc]init];
    switch (status) {
        case 0:
            authStatus = @"Not Determined";
            break;
        case 1:
            authStatus = @"Restricted";
            break;
        case 2:
            authStatus = @"Denied";
            break;
        case 3:
            authStatus = @"Authorized";
            break;
        default:
            authStatus = @"Default case";
            break;
    }
    NSLog(@"Location Manager changed auth status. Now: %u", status);
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    
    NSLog(@"Location Manager entered in region: %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Location Manager exited region: %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Location Manager started Monitoring for region %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Location Manager Monitoring did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSArray *beaconsFound = beacons;
    
    if (beaconsFound > 0) {
        self.closestBeacon = [beaconsFound objectAtIndex:0];
        [self.downloadManager fetchDataOfRestaraunt:self.closestBeacon.major];
    }
    
    NSLog(@"Location Manager did range beacons in region %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Location Manager did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *status = [[NSString alloc]init];
    switch (state) {
        case 0:
            status = @"CLRegion State Unknown";
            break;
        case 1:
            status = @"CLRegion State Inside";
            [self startRanging];
            break;
        case 2:
            status = @"CLRegion State Outside";
            break;
        default:
            status = @"Default Case";
            break;
    }
    NSLog(@"Location Manager did determine state \"%@\" in region %@", status, [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location Manager did Fail with Error: %@, %@", [error localizedDescription], [error localizedFailureReason]);
}

@end
