//
//  BMLocationManager.m
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//

#import "BMLocationManager.h"
#import "BMDownloadManager.h"

//#define BMBEACON @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"
#define BMBEACON @"96A1736B-11FC-85C3-1762-80DF658F0B29"

@import UIKit;
@import CoreBluetooth;

@interface BMLocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *bmBeaconRegion;
@property (nonatomic, strong) NSUUID *BMUUID;
@property (nonatomic, strong) CLBeacon *closestBeacon;

@property (nonatomic, strong) BMDownloadManager *downloadManager;

@property (nonatomic, strong) NSDate *lastExitDate;
@property (nonatomic, strong) NSDate *lastEntryDate;
@property (nonatomic, strong) NSDate *lastNotificationDate;
@property (nonatomic, strong) NSString *beaconDistance;

//Every scan in didRangeBeacons increments this counter of 1
@property int timerCounter;

@property BOOL isRanging;

// Setup checks
@property BOOL trackLocationNotified;
@property (readonly) BOOL canTrackLocation;
@property BOOL setupCompleted;
@property BOOL bluetoothEnabled;

@property BOOL isBlueMateInterfacePresented;

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

/*
 Inizializzazione componenti essenziali
 -> settings manager
 */
-(id)initUniqueInstance
{
    self = [super init];
    if (self) {
        NSLog(@"Initialization BMSdk");
        
        self.isBlueMateInterfacePresented = NO;
        
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
        NSLog(@"Beacon Tracking Unavailable");
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
    
    NSLog(@"%@", errorMessage);
    return NO;
    
}

#pragma mark -
/**
 Activates the notifications only if the beacon is seen in a available hour
 */
-(BOOL)canShowNotification
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComponents = [calendar components:NSHourCalendarUnit fromDate:date];
    
    long hour = [dateComponents hour];
    
    if (hour <= 6 || hour >= 0) {
        NSLog(@"Test");
    }
    
    return YES;
}


/**
 Completes the setup of this class
 */
-(void)setupManager
{
 
#if TARGET_IPHONE_SIMULATOR
    [self.downloadManager fetchMenuOfRestaurantWithMajor:@161 andMinor:@243];
#endif
    
    
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
    
    [self startRanging];
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
    NSLog(@"[Location Manager] changed auth status. Now: %u", status);
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
    
    NSLog(@"[Location Manager] entered in region: %@", [region identifier]);
    
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

    NSLog(@"[Location Manager] exited region: %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"[Location Manager] started Monitoring for region %@", [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"[Location Manager] Monitoring did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
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
                if (!self.isBlueMateInterfacePresented) {
                    //Present Interface
                    self.isBlueMateInterfacePresented = YES;
                }
                [self stopRanging];

                notification.alertBody = [NSString stringWithFormat:@"Proximity: %ld, ID: %@", (long)self.closestBeacon.proximity, self.closestBeacon.minor];
                [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
            }
            else
            {
                if (self.timerCounter == 0) {
                    NSNumber *locatedRestaurantMajor = self.closestBeacon.major;
                    NSNumber *locatedRestaurantMinor = self.closestBeacon.minor;
                    NSLog(@"%@", [self.closestBeacon description]);
                    
                    [[NSUserDefaults standardUserDefaults]setObject:locatedRestaurantMajor forKey:@"majorBeacon"];
                    [[NSUserDefaults standardUserDefaults]setObject:locatedRestaurantMinor forKey:@"minorBeacon"];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                    
                    [self.downloadManager fetchMenuOfRestaurantWithMajor:self.closestBeacon.major andMinor:self.closestBeacon.minor];
                }
                self.timerCounter++;
            }
        }
    }
    
    NSLog(@"[Location Manager] did range %lu beacons in region %@", (unsigned long)[beacons count], [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"[Location Manager] did Fail For Region: %@, %@, %@", [region identifier], [error localizedDescription], [error localizedFailureReason]);
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
    NSLog(@"[Location Manager] did determine state \"%@\" in region %@", status, [region identifier]);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"[Location Manager] did Fail with Error: %@, %@", [error localizedDescription], [error localizedFailureReason]);
}

#pragma mark - Determine current view

-(UIViewController *)topViewController
{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

-(UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers]lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end
