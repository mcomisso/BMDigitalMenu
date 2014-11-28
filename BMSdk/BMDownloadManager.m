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
#import "Constants.h"

#define DEBUGGER NO

@import UIKit;

@interface BMDownloadManager()

@property BOOL isNetworkAvailable;
@property (nonatomic, readwrite) BOOL isMenuDownloaded;
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
        [self isConnectionAvailable];
        self.AFmanager = [AFHTTPRequestOperationManager manager];
        self.AFmanager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [self.AFmanager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"ios_client" password:@"189vMktXsnd3V4mH1BAQ2q9eT6Je0H0Tds9svK0KSJ4"];
    }
    return self;
}

#pragma mark - New Backend First Caller
-(void)fetchMenuOfRestaurantWithMajor:(NSNumber *)majorNumber andMinor:(NSNumber *)minorNumber
{

    if (self.isNetworkAvailable) {
        
        BMDataManager *dataManager = [BMDataManager sharedInstance];
        
        //GET request for downloading the menu starting from the beacons parameters
        [_AFmanager GET:[BMAPI_RECIPES_FROM_MAJ_MIN stringByAppendingString:[NSString stringWithFormat:@"%@/%@/?format=json", [majorNumber stringValue], [minorNumber stringValue]]]
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"Completed Download of the menu, response: %@", [responseObject description]);
                    int numbersOfRecipes = (int)[[responseObject objectForKey:@"count"]integerValue];
                    NSString *restaurantSlug = responseObject[@"results"][0][@"restaurant"][@"slug"];
                    //If > 0 -> save recipes
                    if (numbersOfRecipes) {
                        //Ask the datamanager to save recipes
                        [dataManager deleteDataFromRestaurant:restaurantSlug];
                        
                        [dataManager saveMenuData:[responseObject objectForKey:@"results"]];
                    }
                    else
                    {
                        //Il menu non contiene ricette
                        NSLog(@"Il menu scaricato non contiene alcuna ricetta");
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Error downloading the menu");
                    NSLog(@"%@, %@", [error localizedDescription], [error localizedFailureReason]);
                }];
    }
}

-(void)fetchDayMenuOfRestaurantWithMajor:(NSNumber *)majorNumber andMinor:(NSNumber *)minorNumber
{
    // GET FOR Day MENU
    [_AFmanager GET:[BMAPI_DAYMENU_FROM_MAJ_MIN stringByAppendingString:[NSString stringWithFormat:@"%@/%@/?format=json", [majorNumber stringValue], [minorNumber stringValue]]]
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                int numbersOfRecipes = (int)[[responseObject objectForKey:@"count"]integerValue];
                if (numbersOfRecipes) {
                    //Visualize the button and serve the recipes of the day.
                    NSLog(@"Day Menu downloaded");
                    
                    //TODO: Save Day Menu
                    //[dataManager saveDayMenu:[responseObject objectForKey:@"results"]];
                }
                else
                {
                    //No day menu. Don't visualize the button.
                    NSLog(@"No day menu entries");
                }
                
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error while downloading day menu: %@, %@", [error localizedDescription], [error localizedFailureReason]);
            }];
}

#pragma mark - Utils
-(void)fetchLatestRecipeOfRestaurant:(NSNumber *)majorNumber
{
    [_AFmanager GET:[BMAPI_RECIPES_FROM_MAJ_MIN stringByAppendingString:@"menu/"]
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

#pragma mark - Comments and rating
/**
 Fetches the comments for a recipe
 @param idRecipe
 */
-(void)fetchCommentsForRecipe:(NSString *)recipeSlug
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    [_AFmanager GET:[BMAPI_COMMENTS_FOR_RECIPE_SLUG stringByAppendingString:[NSString stringWithFormat:@"%@/?format=json", recipeSlug]]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSLog(@"[DownloadManager] Comments description: %@", [responseObject description]);
               
               [dataManager saveCommentsData:responseObject];
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"[Download Manager] Cannot download data for comments: %@, %@", [error localizedDescription], [error localizedFailureReason]);
           }];
}

-(void)fetchRatingForRecipe:(NSString *)recipeSlug
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    [_AFmanager GET:[BMAPI_RATING_FOR_RECIPE_SLUG stringByAppendingString:[NSString stringWithFormat:@"%@/?format=json", recipeSlug]]
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               //saveRatingData
               int ratingValue = (int)[[responseObject objectForKey:@"rating"]integerValue];
               [dataManager saveRatingValue:[NSNumber numberWithInt:ratingValue] forRecipe:recipeSlug];
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
