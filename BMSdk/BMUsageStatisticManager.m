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
#import <sys/utsname.h>

#define POLLINGTIMER 20

#define BMPARSEAPI @"https://api.parse.com/1/"

// Test Parse REST
#define APPLICATION_ID @"aHSvZObWED0XrBDCqbL6eeO01tCXmdFTyRH9oY2V"
#define REST_API @"H9HXKUKQTtpq3F69PDyj0fnfQ8iTYV02JZqEwfeG"

//DEFINE A NEW SQLITE DB


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

@end

@implementation BMUsageStatisticManager

+(BMUsageStatisticManager *)sharedInstance
{
    static BMUsageStatisticManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
        [BMUsageStatisticManager checkIphoneType];
    });
    
    return sharedInstance;
}

-(instancetype)initUniqueInstance
{
    self = [super init];
    if (self != nil) {
        //Add observers for terminating and resignation
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        DLog(@"[Usage Statistic] BMUsageStatistic initialized");
        _categoriesViewed = [[NSMutableArray alloc]init];
        _info = [[NSMutableDictionary alloc]init];
        
        _reachManager = [AFBMNetworkReachabilityManager sharedManager];

        _manager = [AFBMHTTPRequestOperationManager manager];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
        _dataMonitoringQueue = _manager.operationQueue;
        // SAVE THE DISPLAY SIZE
        
        [_reachManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (status == AFNetworkReachabilityStatusNotReachable) {
                // Save data in DB
                
            }
            else if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN)
            {
                // Send data
                
            }
        }];
        
    }
    return self;
}

#pragma mark - App States instances

-(void)appWillBecomeActive:(NSNotification *)note
{
    //Check if data exists inside DB, restore timer run
    //send to parse existing data
    
}

-(void)appWillTerminate:(NSNotification *)note
{
    DLog(@"Usage Manager: app will terminate");
    //Save everyting not sent on DB
    //Stop timer run
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

-(void)appWillResignActive:(NSNotification*)note
{
    DLog(@"Usage Manager: app will resign active");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - Collect data
/*-(NSData *)jsonConvert:(NSMutableArray *)dictionary
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
}
*/

-(void)sendEventually:(NSDictionary *)data
{
    NSDictionary *params = @{data : @"data"};
    __weak NSOperationQueue *weakQueue = _dataMonitoringQueue;
    
    [_manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                //Something when not reachable
                //Save data inside the db
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                //Something online
                //Send data
                break;
            case AFNetworkReachabilityStatusUnknown:
                //Save data inside the db
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                //Send data
                
                break;
                
            default:
                break;
        }
    }];
    
    [_manager POST:BMPARSEAPI
       parameters:params
          success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
              //DELETE THIS DATA
              
          } failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
              //SAVE AND RETRY
        
          }];
}

-(void)sendData
{
    
    [_manager POST:BMPARSEAPI
        parameters:0
           success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
               //DELETE THIS DATA

           } failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
               //SAVE AND RETRY

           }];
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

-(void)testConnectionToParse
{
    NSURL *baseUrl = [NSURL URLWithString:[BMPARSEAPI stringByAppendingString:@"classes/Analytics"]];
    [_manager GET:[baseUrl absoluteString]
       parameters:@{@"X-Parse-Application-Id":APPLICATION_ID,
                    @"X-Parse-REST-API-Key":REST_API,
                    }
          success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
              
              DLog(@"%@",[responseObject description]);
          }
          failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
              DLog(@"error: %@ %@", [error localizedDescription], [error localizedFailureReason]);
          }];
}

-(void)saveViewControllerName:(id)viewController
{
    
}

#pragma mark - utils

+(NSString *)checkIphoneType
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *sysInformation = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    DLog(@"%@", sysInformation);
    return sysInformation;
}

@end
