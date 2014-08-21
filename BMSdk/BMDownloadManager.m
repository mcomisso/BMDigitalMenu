//
//  BMDownloadManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMDownloadManager.h"
#import "Reachability.h"
#import "AFNetworking.h"

#define BMAPI @"http://54.76.193.225/api/v1/client/"
#define BMIMAGES @"http://54.76.193.225/static/images/"

@import UIKit;

@interface BMDownloadManager()

@property BOOL isNetworkAvailable;

@property (nonatomic, readwrite) BOOL isMenuDownloaded;
@property (nonatomic, readwrite) NSString *bmUrl;

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
        self.bmUrl = BMIMAGES;
        [self isConnectionAvailable];
    }
    return self;
}

-(void)fetchDataOfRestaraunt:(NSNumber *)majorNumber
{
    if (self.isNetworkAvailable) {
        if (!_isMenuDownloaded) {
//            NSString *majorNumberStringValue = [majorNumber stringValue];

//#warning Remove the minor number once backend is working
//            NSURL *requestMenuData = [[NSURL alloc]initWithString:[[BMAPI stringByAppendingString:majorNumberStringValue]stringByAppendingString:@"/4"]];
            
#warning single restaraunt request
            NSURL *requestMenuData = [[NSURL alloc]initWithString:[BMAPI stringByAppendingString:@"menu"]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestMenuData];
            NSURLResponse *response = nil;
            NSError *error = nil;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if (!error) {
                NSArray *parsedMenu = [[self parseData:data of:@"menu"] copy];
                if ([[parsedMenu objectAtIndex:0] objectForKey:@"Error"]) {
                    NSLog(@"[Download Manager] Error! %@", parsedMenu[0][@"Error"]);
//Show a message for noticed problem
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:[[parsedMenu objectAtIndex:0] objectForKey:@"Error"] delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
                    [alert show];
                }
                else
                {
                    NSLog(@"[Download manager] Parsed menu: %@", [parsedMenu description]);
                    [self saveOnDatabase:parsedMenu];
                    self.isMenuDownloaded = YES;
                }
            }
        }
        else
        {
            // Network connection error
            NSLog(@"[Download manager] Network Connection error");
        }
    }
}

-(NSMutableArray *)parseData:(NSData *)dataToParse of:(NSString*)categoryToParse
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
    NSArray *menuArray = nil;

    if ([categoryToParse isEqualToString:@"menu"]) {
        menuArray = menuDictionary[@"ricette"];
    }
    else
    {
        menuArray = menuDictionary[@"commenti"];
    }
    NSMutableArray *returner = [[NSMutableArray alloc]initWithArray:menuArray copyItems:YES];
    
    return returner;
}


-(void)saveOnDatabase:(NSArray *)toBeSaved
{
    BMDataManager *dataManagerS = [BMDataManager sharedInstance];
    NSLog(@"[Download manager] Request to save data");
    [dataManagerS saveMenuData:toBeSaved];
}

-(void)fetchCommentsForRecipe:(NSString *)idRecipe
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];

    AFHTTPRequestOperationManager *afmanager = [AFHTTPRequestOperationManager manager];
    [afmanager GET:[[BMAPI stringByAppendingString:@"comment/"]stringByAppendingString:idRecipe]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSLog(@"[DownloadManager] Comments description: %@", [responseObject description]);
               
               [dataManager saveCommentsData:[self parseData:responseObject of:@"comments"]];
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"[Download Manager] Cannot download data for comments");
           }];
    
}

-(void)fetchRatingForRecipe:(NSString *)idRecipe
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    AFHTTPRequestOperationManager *afmanager = [AFHTTPRequestOperationManager manager];
    
    [afmanager GET:[[BMAPI stringByAppendingString:@"vote/"]stringByAppendingString:idRecipe]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               //saveRatingData
               
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               //Save into db
               NSLog(@"[Download Manager] Failed Fetch of rating recipe %@ , %@", [error localizedDescription], [error localizedFailureReason]);
           }];
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

-(void)aliveConnection
{
    NSString *presentUser = [[NSUserDefaults standardUserDefaults]objectForKey:@"user"];
    
    if (presentUser == nil) {
        NSString *user = [NSString stringWithFormat:@"%u", arc4random()];
        [[NSUserDefaults standardUserDefaults]setObject:user forKey:@"user"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        presentUser = user;
    }
    
    //Ping a specific api with some private key to show the usage and an unique identifier.
}



@end
