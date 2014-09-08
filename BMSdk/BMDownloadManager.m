//
//  BMDownloadManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMDownloadManager.h"
#import "BMLocationManager.h"
#import "Reachability.h"
#import "AFNetworking.h"

#define BMAPI @"http://54.76.193.225/api/v1/client/"
#define BMIMAGES @"https://s3-eu-west-1.amazonaws.com/bmbackend/"

#define DEBUGGER NO

@import UIKit;

@interface BMDownloadManager()

@property BOOL isNetworkAvailable;

@property (nonatomic, readwrite) BOOL isMenuDownloaded;
@property (nonatomic, readwrite) NSString *bmUrl;
@property (nonatomic, strong) NSString *locale;

@property (nonatomic, strong) AFHTTPRequestOperationManager *AFmanager;

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
        self.locale = [[NSLocale preferredLanguages]objectAtIndex:0];
        self.AFmanager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    }
    return self;
}

#pragma mark - First Caller
-(void)fetchMenuOfRestaraunt:(NSNumber *)restarauntMajorNumber
{
    [self checkTypeOfMenu:restarauntMajorNumber];
}

#pragma mark - Download methods

-(void)fetchPDFOfRestaraunt:(NSNumber *)majorNumber
{
    NSString *urlMenu = [BMAPI stringByAppendingString:@"menu/pdf"];
    
    if (self.isNetworkAvailable) {
        if (!_isMenuDownloaded) {
            [_AFmanager GET:urlMenu parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     
                     BMDataManager *dataManager = [BMDataManager sharedInstance];
                     
                     NSLog(@"URL of pdf id: %@", [responseObject description]);
                     NSString *pdfURL = [responseObject objectForKey:@"url"];
                     NSArray *urlName = [pdfURL componentsSeparatedByString:@"/"];
                     
                     //Save Name of pdf inside Database
                     [dataManager savePDFUuid:[urlName lastObject] ofRestaraunt:@"CAMBIARE"];
                     
                     //Download and save pdf file to filepath
                     NSString *filePath = [[dataManager pathToPDFDirectory]stringByAppendingPathComponent:[urlName lastObject]];
                     
                     NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfURL]];
                     AFHTTPRequestOperation *downloadOperation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
                     
                     downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
                     
                     [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                         NSLog(@"Percent completed: %f", (float)totalBytesRead/totalBytesExpectedToRead);
                     }];
                     
                     [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                         //DONE
                         NSLog(@"Download complete");
                         _isMenuDownloaded = YES;
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         //FAILURE
                         NSLog(@"Error while downloading pdf: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                     }];
                     
                     [downloadOperation start];
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"Error while getting URL of pdf: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                 }];
            
        }
    }
}

-(void)fetchJSONOfRestaraunt:(NSNumber *)majorNumber
{
    BMLocationManager *locationManager = [BMLocationManager sharedInstance];
    
    if (self.isNetworkAvailable) {
        if (!_isMenuDownloaded) {
            [locationManager stopRanging];
//            NSString *majorNumberStringValue = [majorNumber stringValue];
//            NSURL *requestMenuData = [[NSURL alloc]initWithString:[[BMAPI stringByAppendingString:majorNumberStringValue]stringByAppendingString:@"/4"]];

            //TODO: multiple restaraunt management
            NSURL *requestMenuData = [[NSURL alloc]initWithString:[BMAPI stringByAppendingString:@"menu"]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestMenuData];
            NSURLResponse *response = nil;
            NSError *error = nil;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
            
            if (!error) {
                BMDataManager *dataManager = [BMDataManager sharedInstance];
                //TODO: Restaraunt must be programmatically inserted
                NSString *stringDateOfLastSavedRecipe = [[dataManager latestMenuEntryOfRestaraunt:@"CAMBIARE"] copy];
                int savedRecipes = [dataManager numberOfrecipesInCache];
                
                NSArray *parsedMenu = [[self parseData:data of:@"menu"] copy];

                if ([[parsedMenu objectAtIndex:0] objectForKey:@"Error"]) {
                    NSLog(@"[Download Manager] Error! %@", parsedMenu[0][@"Error"]);
                
                    [locationManager stopRanging];

                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:[[parsedMenu objectAtIndex:0] objectForKey:@"Error"] delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
                    [alert show];
                }
                else
                {
                    [locationManager stopRanging];
                    
                    if (DEBUGGER) {
                        [dataManager deleteDataFromRestaraunt:@"restaraunt"];
                    }
                    
//                    NSLog(@"[Download manager] Parsed menu: %@", [parsedMenu description]);
                    
                    NSDictionary *latestRecipe =[parsedMenu objectAtIndex:[parsedMenu count]-1];

                    NSDateFormatter *df = [[NSDateFormatter alloc]init];
                    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    
                    NSString *formattedServerString = [[[latestRecipe objectForKey:@"data_ultima_modifica"]componentsSeparatedByString:@"."]objectAtIndex:0];

                    NSString *formattedCachedString = [[stringDateOfLastSavedRecipe componentsSeparatedByString:@"."]objectAtIndex:0];

                    double timeIntervalFromServer = [[df dateFromString:formattedServerString] timeIntervalSince1970];
                    double timeIntervalFromCache = [[df dateFromString:formattedCachedString] timeIntervalSince1970];
                    
                    if (timeIntervalFromCache == 0) {
                        [dataManager saveMenuData:parsedMenu];
                    }
                    else if (timeIntervalFromServer > timeIntervalFromCache || [parsedMenu count] < savedRecipes) {
                        [dataManager deleteDataFromRestaraunt:@"restaraunt"];
                        [dataManager saveMenuData:parsedMenu];
                    }
                    self.isMenuDownloaded = YES;
                }
            }
        }
        else
        {
            // Network connection error
            [locationManager stopRanging];
            NSLog(@"[Download manager] Network Connection error");
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Network error" message:@"Controllare la disponibilità di rete del dispositivo, non è possibile scaricare il menù del ristorante." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

#pragma mark - Utils
-(void)fetchLatestRecipeOfRestaraunt:(NSNumber *)majorNumber
{
    [_AFmanager GET:[BMAPI stringByAppendingString:@"menu/"]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               //saveRatingData
               [self performSelector:@selector(latestFetchedDate:) withObject:responseObject];
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               //Something wrong happened
               NSLog(@"[Download Manager] Failed Fetch of rating recipe %@ , %@", [error localizedDescription], [error localizedFailureReason]);
           }];
}

-(void)checkTypeOfMenu:(NSNumber *)majorNumber
{
    NSString *url = [BMAPI stringByAppendingString:@"type"];
    
    [_AFmanager GET:url
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSString *pdfAvailable = [responseObject objectForKey:@"pdf"];
               NSString *menuAvailable = [responseObject objectForKey:@"menu"];
               
               if (![menuAvailable isEqualToString:@"Yes"]) {
                   //Download Menu
                   [self performSelector:@selector(fetchJSONOfRestaraunt:) withObject:majorNumber];
               }
               else
               {
                   if ([pdfAvailable isEqualToString:@"Yes"]) {
                       //Download pdf
                       [self performSelector:@selector(fetchPDFOfRestaraunt:) withObject:majorNumber];
                   }
                   else
                   {
                       // NO MENU OR PDF AVAILABLE
                       NSLog(@"NO MENU OR PDF AVAILABLE");
                   }
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               //DISPLAY ERROR CONNECTION
               NSLog(@"[Download Manager]Error while checking type of menu -> %@ %@", [error localizedDescription], [error localizedFailureReason]);
           }];
}

-(void)latestFetchedDate:(NSData *)data
{
    NSArray *arrayOfRecipes = [self parseData:data of:@"menu"];
    
    NSLog(@"[Download manager] Array description: %@ ", [arrayOfRecipes description]);
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

#pragma mark - Comments and rating
-(void)fetchCommentsForRecipe:(NSString *)idRecipe
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    [_AFmanager GET:[[BMAPI stringByAppendingString:@"comment/"]stringByAppendingString:idRecipe]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSLog(@"[DownloadManager] Comments description: %@", [responseObject description]);
               
               [dataManager saveCommentsData:responseObject];
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"[Download Manager] Cannot download data for comments: %@, %@", [error localizedDescription], [error localizedFailureReason]);
           }];
    
}

-(void)fetchRatingForRecipe:(NSString *)idRecipe
{
//    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    [_AFmanager GET:[[BMAPI stringByAppendingString:@"vote/"]stringByAppendingString:idRecipe]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               //saveRatingData
               
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               //Something wrong happened
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

@end
