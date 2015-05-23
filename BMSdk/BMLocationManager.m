//
//  BMLocationManager.m
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//

#import "BMLocationManager.h"
#import "BMDownloadManager.h"

#define BMBEACON @"96A1736B-11FC-85C3-1762-80DF658F0B29"

@import UIKit;
@import CoreBluetooth;

@interface BMLocationManager() <CLLocationManagerDelegate, CBCentralManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *bmBeaconRegion;
@property (nonatomic, strong) NSUUID *BMUUID;
@property (nonatomic, strong) CLBeacon *closestBeacon;

@property (nonatomic, strong) BMDownloadManager *downloadManager;

@property (nonatomic, strong) NSDate *lastExitDate;
@property (nonatomic, strong) NSDate *lastEntryDate;
@property (nonatomic, strong) NSDate *lastNotificationDate;
@property (nonatomic, strong) NSString *beaconDistance;

// Bluetooth manager part
@property (nonatomic, strong) CBCentralManager *bluetoothManager;

//Every scan in didRangeBeacons increments this counter of 1
@property int timerCounter;
@property BOOL isRanging;

// Setup checks
@property BOOL trackLocationNotified;
@property (readonly) BOOL canTrackLocation;
@property BOOL setupCompleted;
@property BOOL bluetoothEnabled;

@property BOOL restaurantFound;
@property (readwrite, nonatomic) BOOL canStartInterface;

@property (nonatomic) UIBackgroundTaskIdentifier downloadTask;

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

/**
 Inizializzazione componenti essenziali
 -> settings manager
 */
-(id)initUniqueInstance
{
    self = [super init];
    if (self) {
        DLog(@"Initialization BMSdk");
        
        // Notification explicitally called on entry&&exit
        self.bmBeaconRegion.notifyOnEntry = YES;
        self.bmBeaconRegion.notifyOnExit = YES;

        self.trackLocationNotified = NO;
        self.setupCompleted = NO;
        self.isRanging = NO;
        self.restaurantFound = NO;
        self.closestBeacon = [[CLBeacon alloc]init];
        self.BMUUID = [[NSUUID alloc]initWithUUIDString:BMBEACON];
        self.timerCounter = 0;

        //Download Manager
        self.downloadManager = [BMDownloadManager sharedInstance];
        
        [self setupManager];
        
        self.dispatchGroup = dispatch_group_create();
        self.canStartInterface = NO;
    }
    return self;
}


#pragma mark - Check availability and setup
-(BOOL)canTrackLocation
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    NSString *errorMessage;
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        DLog(@"Beacon Tracking Unavailable");
    }
    
    if (![CLLocationManager locationServicesEnabled]) {
        errorMessage = @"locationServices Not enabled";
        if (IS_OS_8_OR_LATER) {
            // Open the settings app
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
    else
    {
        if (![CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
            errorMessage = @"Location Tracking not Available";
            //Check if is iOS 8 or not
            if (IS_OS_8_OR_LATER) {
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
            else
            {
                //Comunicate the user that the Location tracking is unavailable
                //TODO
            }
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
    
    DLog(@"%@", errorMessage);
    return NO;
    
}

/**
 Completes the setup of this class
 */
-(void)setupManager
{
    
    if (!self.canTrackLocation || self.setupCompleted) {
        return;
    }
    
    self.bluetoothEnabled = YES;
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
    
    self.bmBeaconRegion = [[CLBeaconRegion alloc]initWithProximityUUID:self.BMUUID identifier:@"com.bluemate.mssdk"];
    
    [self.locationManager stopMonitoringForRegion:self.bmBeaconRegion];
    [self.locationManager startMonitoringForRegion:self.bmBeaconRegion];
    [self.locationManager requestStateForRegion:self.bmBeaconRegion];
    
    [self.locationManager startUpdatingLocation];
    
    self.setupCompleted = YES;


//    Remove this comment to show the recipes of restaurant n° 1
    [self.downloadManager fetchMenuOfRestaurantWithMajor:@243 andMinor:@161];
    [[NSUserDefaults standardUserDefaults]setObject:@243 forKey:@"majorBeacon"];
    [[NSUserDefaults standardUserDefaults]setObject:@161 forKey:@"minorBeacon"];
    [[NSUserDefaults standardUserDefaults]synchronize];

//    [self startRanging];
}


-(void)initializeBluetoothManager
{
    //Bluetooth Manager status
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerOptionShowPowerAlertKey, nil];
    self.bluetoothManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue() options:options];
    [self centralManagerDidUpdateState:self.bluetoothManager];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString *state = nil;
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth powered OFF";
            self.bluetoothEnabled = NO;
            //Send notification
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"Bluetooth powered ON and available";
            self.bluetoothEnabled = YES;
            //Send notification
            break;
        case CBCentralManagerStateResetting:
            state = @"Connection with system service was lost, resetting";
            self.bluetoothEnabled = NO;
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth Low Energy";
            self.bluetoothEnabled = NO;
            break;
        case CBCentralManagerStateUnknown:
            state = @"State Unknown, update imminent";
            self.bluetoothEnabled = NO;
            break;
        case CBCentralManagerStateUnsupported:
            state = @"State unsupported";
            self.bluetoothEnabled = NO;
            //Send notification to advertise the unsupported device
            break;
        default:
            state = @"State Unknown, update imminent";
            break;
            
    }
    DLog(@"%@",state);
}

#pragma mark - Shortcut methods
-(void)startRanging
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startRangingBeaconsInRegion:self.bmBeaconRegion];
    }
    else
    {
        [self.locationManager startRangingBeaconsInRegion:self.bmBeaconRegion];
    }
    DLog(@"App startRanging");
}

-(void)stopRanging
{
    [self.locationManager stopRangingBeaconsInRegion:self.bmBeaconRegion];
    DLog(@"App stopRanging");
}

-(void)enterBackground
{
    [self stopRanging];
    DLog(@"App enters in background");
}

-(void)enterForeground
{
    [self startRanging];
    DLog(@"App enters in foreground");
}

-(void)startLookingForTable
{
    [self startRanging];
}

//TODO: schedule notification for iOS 8 with UILocalNotification part
-(void)scheduleLocalNotificationForEnteringZone
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        notification.region = self.bmBeaconRegion;
        notification.regionTriggersOnce = YES;
        notification.alertBody = @"Alert for iOS 8";
    }
    else
    {
        notification.alertBody = @"Alert for iOS 7";
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark - BM[Location Manager] Delegate Methods
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString *authStatus = [[NSString alloc]init];

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            authStatus = @"Not Determined";
            //Inform the user that The location services are necessary
            break;
            
        case kCLAuthorizationStatusRestricted:
            authStatus = @"Restricted";
            //Restrictions (can be parental control)
            break;
            
        case kCLAuthorizationStatusDenied:
            authStatus = @"Denied";
            //Inform the user that location services are necessary
            break;

            // It's the same as kCLAuthorizationStatusAuthorized
        case kCLAuthorizationStatusAuthorizedAlways:
            authStatus = @"Authorized";
            [self setupManager];
            break;
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            authStatus = @"Authorized When In Use";
            [self setupManager];
            break;
            
        default:
            authStatus = @"Default case";
            break;
    }
    DLog(@"[Location Manager] changed auth status. Now: %u", status);
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    UILocalNotification *welcomeNotification = [[UILocalNotification alloc]init];
    
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"welcomeMessage"]) {
        welcomeNotification.alertBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"welcomeMessage"];
    }
    else{
        welcomeNotification.alertBody = @"Welcome";
    }
    
    [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    
    DLog(@"[Location Manager] entered in region: %@", [region identifier]);
    
    [[UIApplication sharedApplication]presentLocalNotificationNow:welcomeNotification];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    //If the notification was setted from the
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"goodbyeNotification"]) {
        UILocalNotification *goodbyeNotification = [[UILocalNotification alloc]init];
        goodbyeNotification.alertBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"goodbyeNotification"];
        [[UIApplication sharedApplication]presentLocalNotificationNow:goodbyeNotification];
    }

    DLog(@"[Location Manager] exited region: %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    DLog(@"[Location Manager] started Monitoring for region %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DLog(@"[Location Manager] Monitoring did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
}

/*
 Il major number del beacon più vicino corrisponde al numero id del ristorante.
 */
-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    
    if ([beacons count] > 0) {
        //Filter out the beacons Unknown
        beacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity != %d", CLProximityUnknown]];
        self.closestBeacon = [beacons firstObject];
        if (self.closestBeacon.proximity != CLProximityUnknown) {
            
            // If user keep stayin in same zone for 3 seconds, check and fetch data for Restaurant
            if (self.timerCounter == 3) {
                
                [self stopRanging];

                notification.alertBody = [NSString stringWithFormat:@"Proximity: %ld, ID: %@", (long)self.closestBeacon.proximity, self.closestBeacon.minor];
                [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
            }
            else
            {
                if (self.timerCounter == 0) {
                    NSNumber *locatedRestaurantMajor = self.closestBeacon.major;
                    NSNumber *locatedRestaurantMinor = self.closestBeacon.minor;
                    DLog(@"%@", [self.closestBeacon description]);
                    
                    [[NSUserDefaults standardUserDefaults]setObject:locatedRestaurantMajor forKey:@"majorBeacon"];
                    [[NSUserDefaults standardUserDefaults]setObject:locatedRestaurantMinor forKey:@"minorBeacon"];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                    
                    [self.downloadManager fetchMenuOfRestaurantWithMajor:self.closestBeacon.major andMinor:self.closestBeacon.minor];
                }
                self.timerCounter++;
            }
        }
    }
    
    DLog(@"[Location Manager] did range %lu beacons in region %@", (unsigned long)[beacons count], [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DLog(@"[Location Manager] did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *status = [[NSString alloc]init];
    switch (state) {
        case 0:
            status = @"CLRegion State Unknown";
            [[NSNotificationCenter defaultCenter]postNotificationName:@"disableButton" object:nil];
            break;
        case 1:
            status = @"CLRegion State Inside";
            [[NSNotificationCenter defaultCenter]postNotificationName:@"enableButton" object:nil];
            [self startRanging];
            break;
        case 2:
            status = @"CLRegion State Outside";
            [[NSNotificationCenter defaultCenter]postNotificationName:@"disableButton" object:nil];
            [self stopRanging];
            break;
        default:
            [[NSNotificationCenter defaultCenter]postNotificationName:@"disableButton" object:nil];
            status = @"Default Case";
            break;
    }
    DLog(@"[Location Manager] did determine state \"%@\" in region %@", status, [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"[Location Manager] did Fail with Error: %@, %@", [error localizedDescription], [error localizedFailureReason]);
}

@end
