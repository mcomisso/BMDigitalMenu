//
//  BMUsageStatisticManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 04/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMUsageStatisticManager.h"
#import "BMDataManager.h"
#import "AFHTTPRequestOperationManager.h"

#import "AFNetworkReachabilityManager.h"
#import <sys/utsname.h>

#define BMAPI @""

@interface BMUsageStatisticManager()

@property (strong, nonatomic) NSString *presentUser;
@property (strong, nonatomic) NSDate *enterTime;
@property (strong, nonatomic) NSDate *exitTime;

@property (strong, nonatomic) NSNumber *beaconMajor;
@property (strong, nonatomic) NSNumber *beaconMinor;

@property (strong, nonatomic) NSMutableArray *categoriesViewed;

@property (strong, nonatomic) NSMutableDictionary *info;

@property (strong, nonatomic) NSOperationQueue *dataMonitoringQueue;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) AFNetworkReachabilityManager *reachManager;

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
        
        NSLog(@"[Usage Statistic] BMUsageStatistic initialized");
        _categoriesViewed = [[NSMutableArray alloc]init];
        _info = [[NSMutableDictionary alloc]init];
        
        _reachManager = [AFNetworkReachabilityManager sharedManager];

        _manager = [AFHTTPRequestOperationManager manager];
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
    
}

-(void)appWillTerminate:(NSNotification *)note
{
    NSLog(@"Usage Manager: app will terminate");
    //Save everyting not sent on DB

    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

-(void)appWillResignActive:(NSNotification*)note
{
    NSLog(@"Usage Manager: app will resign active");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - Collect data
-(void)collectDescription:(NSString *)description withKey:(NSString *)key
{
    
}

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

                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                //Something online

                break;
            case AFNetworkReachabilityStatusUnknown:

                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:

                break;
                
            default:
                break;
        }
    }];
    
    [_manager POST:BMAPI
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              //DELETE THIS DATA
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

-(void)saveViewControllerName:(id)viewController
{
    
}

#pragma mark - utils

+(NSString *)checkIphoneType
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *sysInformation = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", sysInformation);
    return sysInformation;
}

@end
