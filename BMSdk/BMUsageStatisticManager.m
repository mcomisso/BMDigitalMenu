//
//  BMUsageStatisticManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 04/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMUsageStatisticManager.h"
#import "AFHTTPRequestOperationManager.h"

#define ENDPOINT @""

@interface BMUsageStatisticManager()

@property (strong, nonatomic) NSDate *enterTime;
@property (strong, nonatomic) NSDate *exitTime;

@property (strong, nonatomic) NSNumber *beaconMajor;
@property (strong, nonatomic) NSNumber *beaconMinor;

@property (strong, nonatomic) NSMutableArray *categoriesViewed;

@property (strong, nonatomic) NSMutableDictionary *info;

@property (strong, nonatomic) NSOperationQueue *dataMonitoringQueue;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;

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
        NSLog(@"[Usage Statistic] BMUsageStatistic initialized");
        _categoriesViewed = [[NSMutableArray alloc]init];
        _info = [[NSMutableDictionary alloc]init];
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        _dataMonitoringQueue = _manager.operationQueue;
    }
    return self;
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
    

    
    [_manager POST:ENDPOINT
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              //DELETE THIS DATA
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              //SAVE AND RETRY
        
          }];
}

-(BOOL)determineNetworkReachability
{
    return YES;
}

@end
