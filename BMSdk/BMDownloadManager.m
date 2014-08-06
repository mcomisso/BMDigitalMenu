//
//  BMDownloadManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMDownloadManager.h"
#import "Reachability.h"

#define BMAPI @"http://54.76.193.225/api/v1/"



@interface BMDownloadManager()

@property BOOL isNetworkAvailable;
@property (nonatomic, readwrite) BOOL isMenuDownloaded;

@end

@implementation BMDownloadManager

//Download and store methods
+(BMDownloadManager *)sharedInstance
{
    static BMDownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}

-(id)initUniqueInstance
{
    self = [super init];
    if (self != nil) {
        NSLog(@"BMDownload Manager initialized");
        [self isConnectionAvailable];
    }
    return self;
}

-(void)fetchDataOfRestaraunt:(NSNumber *)majorNumber
{
    if (self.isNetworkAvailable) {
        NSString *majorNumberStringValue = [majorNumber stringValue];
        
        NSURL *requestMenuData = [[NSURL alloc]initWithString:[[BMAPI stringByAppendingString:majorNumberStringValue]stringByAppendingString:@"/4"]];
        
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestMenuData];
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (!error) {
            NSDictionary *parsedMenu = [[self parseData:data] copy];
            
            NSLog(@"Parsed menu : %@", [parsedMenu description]);
            
            [self saveOnCoreData:parsedMenu];
        }
    }
}

-(NSMutableDictionary *)parseData:(NSData *)dataToParse
{
    NSString *fetchedData = [[NSString alloc] initWithData:dataToParse encoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    
    NSMutableDictionary *menuDictionary = [[NSMutableDictionary alloc]init];
    menuDictionary = [NSJSONSerialization JSONObjectWithData:[fetchedData dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];

    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return  nil;
    }
    
    NSMutableArray *menuArray = menuDictionary[@"menu"];
    NSString *menu = menuArray[0];
    NSMutableDictionary *mutableDict = nil;
    if (menu) {
        NSData *data = [menu dataUsingEncoding:NSUTF8StringEncoding];
        NSError *convertingError = nil;

        mutableDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments && NSJSONReadingMutableContainers error:&convertingError];
        
        if (convertingError) {
            NSLog(@"Error while converting to JSON %@", convertingError);
            return nil;
        }
    }

    self.isMenuDownloaded = YES;
    return mutableDict;
}


-(BOOL)saveOnCoreData:(NSDictionary *)toBeSaved
{
    return YES;
}

#pragma mark - Network Test

-(void)isConnectionAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) {
        self.isNetworkAvailable = NO;
        NSLog(@"No internet connection");
    }
    else
    {
        self.isNetworkAvailable = YES;
        NSLog(@"Connected To internet");
    }
}

-(NSString *)fetchTest
{
    NSURL *myUrl = [[NSURL alloc]initWithString: @"http://54.76.193.225/api/v1/0/4"];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:myUrl];
    NSURLResponse *resp = nil;
    NSError *err = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&resp
                                                     error:&err];
    if (!err) {
        NSString * printThis =[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[printThis dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

        NSLog(@"JSON Object: %@", [jsonObject description]);
        
        return printThis;
    }
    else
    {
        return @"ERROR";
    }
}

@end
