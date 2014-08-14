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
        NSLog(@"[Download manager] BMDownload Manager initialized");

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
            NSArray *parsedMenu = [[self parseData:data] copy];
            if ([[parsedMenu objectAtIndex:0] objectForKey:@"Error"]) {
                NSLog(@"[Download Manager] Error! %@", parsedMenu[0][@"Error"]);
                //Inform backend of error
            }
            else
            {
                NSLog(@"[Download manager] Parsed menu: %@", [parsedMenu description]);
                [self saveOnDatabase:parsedMenu];
            }
        }
    }
    else
    {
        // Network connection error
        NSLog(@"[Download manager] Network Connection error");
    }
}

-(NSMutableArray *)parseData:(NSData *)dataToParse
{
    NSString *fetchedData = [[NSString alloc] initWithData:dataToParse encoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    
    NSMutableDictionary *menuDictionary = [[NSMutableDictionary alloc]init];
    menuDictionary = [NSJSONSerialization JSONObjectWithData:[fetchedData dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];

    if (error) {
        NSLog(@"[Download manager] Error: %@", [error localizedDescription]);
        return  nil;
    }
    
    NSArray *menuArray = menuDictionary[@"menu"];
    NSMutableArray *returner = [[NSMutableArray alloc]initWithCapacity:[menuArray count]];
    
    for (int i = 0; i < [menuArray count]; i++) {
        
        NSString *menu = menuArray[i];
        NSLog(@"%@",[menu description]);
        NSMutableDictionary *mutableDict = nil;
        
        if (menu) {
            NSData *data = [menu dataUsingEncoding:NSUTF8StringEncoding];
            NSError *convertingError = nil;

            mutableDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments && NSJSONReadingMutableContainers error:&convertingError];
            
            if (convertingError) {
                NSLog(@"[Download manager] Error while converting to JSON %@", convertingError);
                return nil;
            }
            [returner insertObject:mutableDict atIndex:i];
        }

    }
    self.isMenuDownloaded = YES;
    return returner;
}


-(void)saveOnDatabase:(NSArray *)toBeSaved
{
    BMDataManager *dataManagerS = [BMDataManager sharedInstance];
    NSLog(@"[Download manager] Request to save data");
    [dataManagerS saveMenuData:toBeSaved];
}

#pragma mark - Network Test

-(void)isConnectionAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) {
        self.isNetworkAvailable = NO;
        NSLog(@"[Download manager] No internet connection");
    }
    else
    {
        self.isNetworkAvailable = YES;
        NSLog(@"[Download manager] Connected To internet");
    }
}
/*
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

        NSLog(@"[Download manager] JSON Object: %@", [jsonObject description]);
        
        return printThis;
    }
    else
    {
        return @"[Download manager] ERROR";
    }
}
*/
@end
