//
//  BMUsageStatisticManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 04/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMUsageStatisticManager.h"

#import "BMUsageStatisticModel.h"
#import "AFBMHTTPRequestOperationManager.h"
#import "AFBMNetworkReachabilityManager.h"

#import "CocoaSecurity.h"


#define POLLINGTIMER 20

#define BM_ANALYTICS_OPEN_API @"https://bmbackend-misiedo.appspot.com/api/analytics/open/"
#define BM_ANALYTICS_CLOSE_API @"https://bmbackend-misiedo.appspot.com/api/analytics/close/"
#define BM_ANALYTICS_UPDATE_API @"https://bmbackend-misiedo.appspot.com/api/analytics/update/"

@interface BMUsageStatisticManager()

@property (strong, nonatomic) NSString *presentUser;
@property (strong, nonatomic) NSDate *enterTime;
@property (strong, nonatomic) NSDate *exitTime;

@property (strong, nonatomic) NSNumber *beaconMajor;
@property (strong, nonatomic) NSNumber *beaconMinor;

@property (strong, nonatomic) NSMutableArray *categoriesViewed;

@property (strong, nonatomic) NSMutableDictionary *info;

@property (strong, nonatomic) NSOperationQueue *dataMonitoringQueue;
@property (strong, nonatomic) AFBMHTTPRequestOperationManager *manager;
@property (strong, nonatomic) AFBMNetworkReachabilityManager *reachManager;

@property (strong, nonatomic) BMUsageStatisticModel *analyticsLocalManager;

@end


@implementation BMUsageStatisticManager

+(BMUsageStatisticManager *)sharedInstance
{
    static BMUsageStatisticManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}


-(instancetype)initUniqueInstance
{
    self = [super init];
    if (self != nil) {

        [self setupObservers];
        
        DLog(@"[Usage Statistic] BMUsageStatistic initialized");
        _categoriesViewed = [[NSMutableArray alloc]init];
        _info = [[NSMutableDictionary alloc]init];
        
        _reachManager = [AFBMNetworkReachabilityManager sharedManager];

        _manager = [AFBMHTTPRequestOperationManager manager];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
        _dataMonitoringQueue = _manager.operationQueue;
        
        [_reachManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (status == AFNetworkReachabilityStatusNotReachable) {
                // Save data in DB
                // Stop trying to save online
            }
            else if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN)
            {
                // Send data
                // Start sending data online
            }
        }];
    }
    
    return self;
}


#pragma mark - App States instances
-(void)setupObservers
{
    //Add observers for terminating and resignation
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)appWillBecomeActive:(NSNotification *)note
{
    //Check if data exists inside DB
    //send to backend existing data
    DLog(@"Usage Manager: app will become active");
    
    /*
     
     if the analytics manager have something inside its cache database, save to server the data.
     
     */
}

-(void)appWillTerminate:(NSNotification *)note
{
    DLog(@"Usage Manager: app will terminate");
    //Save everyting not sent on Database
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

-(void)appWillResignActive:(NSNotification*)note
{
    DLog(@"Usage Manager: app will resign active");
    // Save everything not yet sent on database
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - POST management
-(void)saveEventually:(NSDictionary *)data
{
    AFNetworkReachabilityStatus status = _manager.reachabilityManager.networkReachabilityStatus;
    
    if (status == AFNetworkReachabilityStatusReachableViaWiFi ||
        status == AFNetworkReachabilityStatusReachableViaWWAN) {
        [_manager POST:BM_ANALYTICS_OPEN_API
            parameters:data
               success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
                   DLog(@"Successfully sent data");
               }
               failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
                   DLog(@"Failure. Error message: %@, %@ - %ld", [error localizedDescription], [error localizedFailureReason], (long)[error code]);
               }];
    } else if (status == AFNetworkReachabilityStatusNotReachable ||
               status == AFNetworkReachabilityStatusUnknown) {
        // Save inside database
        [_analyticsLocalManager saveLocally:data];
    }
}

-(void)aliveConnection
{
    _presentUser = [[NSUserDefaults standardUserDefaults]objectForKey:@"user"];
    
    if (_presentUser == nil) {
        NSString *user = [NSString stringWithFormat:@"%u", arc4random()];
        [[NSUserDefaults standardUserDefaults]setObject:user forKey:@"user"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        _presentUser = user;
    }
    
    //Ping a specific api with some private key to show the usage and an unique identifier.
}

@end
