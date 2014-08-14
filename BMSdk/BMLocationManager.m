//
//  BMLocationManager.m
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//

#import "BMLocationManager.h"
#import "BMDataManager.h"

#define BMBEACON @"66666666-6666-6666-6666-666666666666"

@import UIKit;

@interface BMLocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *bmBeaconRegion;
@property (nonatomic, strong) NSUUID *BMUUID;
@property (nonatomic, strong) CLBeacon *closestBeacon;

@property (nonatomic, strong) BMDataManager *dataManager;

@property (nonatomic, strong) NSDate *lastExitDate;
@property (nonatomic, strong) NSDate *lastEntryDate;
@property (nonatomic, strong) NSDate *lastNotificationDate;
@property (nonatomic, strong) NSString *beaconDistance;

@property BOOL isRanging;
@property BOOL trackLocationNotified;
@property (readonly) BOOL canTrackLocation;
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
        self.isRanging = NO;
        self.closestBeacon = [[CLBeacon alloc]init];
        self.BMUUID = [[NSUUID alloc]initWithUUIDString:BMBEACON];
        
        //Download Manager
        self.dataManager = [BMDataManager sharedInstance];
        
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
    [self.locationManager stopRangingBeaconsInRegion:self.bmBeaconRegion];
    NSLog(@"App stopRanging");
}

-(void)enterBackground
{
    [self stopRanging];
    NSLog(@"App enters in background");
}

-(void)enterForeground
{
    [self startRanging];
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
            [self setupManager];
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

/*
 Il major number del beacon più vicino corrisponde al numero id del ristorante.
 */
-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSArray *beaconsFound = beacons;
    
    // Controllo che siano presenti beacons
    if ([beaconsFound count] > 0) {
        CLBeacon *newFound = [beaconsFound firstObject];
        // se l'utente visualizza per tot secondi il beacon, allora scarico il menù
        if (newFound.proximity != CLProximityUnknown & self.closestBeacon.major == newFound.major) {
            NSLog(@"[Location Manager] Same beacon for 3 seconds");
            [self.dataManager requestDataForRestaraunt:self.closestBeacon.major];
        }
        else
        {
            //Save the new proximity beacon
            NSLog(@"%@", [beacons firstObject]);
            self.closestBeacon = [beaconsFound firstObject];
        }
    }
    
    NSLog(@"Location Manager did range %lu beacons in region %@", [beacons count], [region identifier]);
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
            [self stopRanging];
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
