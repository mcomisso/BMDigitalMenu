//
//  BMDataManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 05/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//
/*
 DESCRIPTION:
 Singleton Class.
 
 La classe BMDataManager si occupa del salvataggio/caching dei documenti prelevati da backend.
 
 
 */
#import <Foundation/Foundation.h>
#import "RecipeInfo.h"

@interface BMDataManager : NSObject

+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));

/**
 Creates and returns an `BMDataManager` object. Instantiate this object only through this class method.
 */
+(BMDataManager *)sharedInstance;
#pragma mark - Save Methods
/**
 Saves the latest fetched menu into the SQLite DataBase
 @param JSONArray json containing all the recipes of a particular restaurant
 */
-(void)saveMenuData:(NSArray *)JSONArray;

/**
 Saves the comments fetched with download manager
 @param commentsArray the array containing all the comments for a particular recipe
 */
-(void)saveCommentsData:(NSDictionary *)commentsDictionary;

/**
 Saves the rating of the loaded recipe
 @param value The current value of rating
 @param recipe The recipe identified
 */
-(void)saveRatingValue:(NSNumber *)value forRecipe:(NSString *)recipe;

/**
 Saves The UUID of the PDF inside the database.
 @param pdfUUID The name of the pdf
 @param restaurant The id of the restaurant
 */
-(void)savePDFUuid:(NSString *)pdfUUID ofRestaurant:(NSString *)restaurant;

/**
 Save the day menu of the restaurant inside the database
 @param JSONArray array of results
 */
-(void)saveDayMenu:(NSArray *)JSONArray;

#pragma mark - Check Methods
/**
 Interrogates the database to fetch all the data of a particular restaurant. Policy: Cache first, then Network if available.
 @param restaurantId The major number of the beacons inside a restaurant.
 @return The date in string format of the latest recipe inside the database.
 */
-(NSString *)latestMenuEntryOfRestaurant:(NSString *)restaurantId;

/**
 Interrogates the existing database to determine if should download data
 @param recipeSlug The unique ID of a recipe
 @return BOOL YES or NO
 */
-(BOOL)shouldFetchCommentsFromServer:(NSString*)recipeSlug;

#pragma mark - Data Request Methods
/**
 Interrogates the database to fetch all and only the categories for the given restaurantMajorNumber

 @param restaurantMajorNumber The major number of a certain restaurant.
 
 */
-(NSArray *)requestCategoriesForRestaurantMajorNumber:(NSNumber *)restaurantMajorNumber andMinorNumber:(NSNumber *)restaurantMinorNumber;

/**
 Interrogates the database to fetch all the data of a particular category. Policy: Only cache.
 
 @param category The category wanted to show.
 @param restaurantId The identification number of the restaurant
 
 */
-(NSArray *)requestRecipesForCategory:(NSString *)category ofRestaurantMajorNUmber:(NSNumber *)restaurantMajorNumber andMinorNumber:(NSNumber *)restaurantMinorNumber;

/**
 Interrogates the database to fetch all the data of a particular recipe. Policy: Only cache. Images are handled as multimedia with SDImageView.
 
 @param recipeSlug The unique Slug of a recipe.
 
 */
-(RecipeInfo *)requestDetailsForRecipe:(NSString *)recipeSlug;

/**
 Interrogates the existing database to fetch the rating of a particular recipe. Returns nil if there's no data to show.

 @param recipeSlug The unique ID of a recipe.
 @param restaurantID The identification number of the restaurant
 
 */
-(int)requestRatingForRecipe:(NSString *)recipeSlug;

/**
 Interrogates the existing database to fetch all the ratings for the selected categories.
 @param category The category "searched"
 @return A dictionary with key value as recipeID and value as average count of rating
 */
-(NSDictionary *)requestRatingForRecipesInCategory:(NSString *)category;

/**
 Interrogates the existing database to fetch the comments for a particular recipe. Returns nil if there's no data to show.

 @param recipeSlug The unique ID of a recipe.
 @return Array containing all the comments available
 */
-(NSArray *)requestCommentsForRecipe:(NSString *)recipeSlug;

/**
 Fetch all data for recipes inserted in "cart"

 @param listOfRecipesToFind Array containing the id's of recipes to find inside the database
 @return array containing all the detailed recipes
 */
-(NSMutableArray *)requestDataForCart:(NSArray*)listOfRecipesToFind;

#pragma mark - Delete from menu

/**
 Deletes all recipes for a partcular restaurant
 @param restaurantSlug Slug of restaurant, which recipes will be deleted.
 */
-(void)deleteDataFromRestaurant:(NSString *)restaurantSlug;

/**
 Deletes all comments for a particular recipe
 @param recipeSlug ID for a particular recipe.
 */
-(void)deleteCommentsOfRecipe:(NSString *)recipeSlug;

/**
 Counts the numbers of recipes currently inside the database.
 @return COUNT(*) of recipes
 */
-(int)numberOfrecipesInCacheForRestaurant;

#pragma mark - PDF utils

/**
 Controls if the PDF directory exists. If not, the method creates one.
 */
-(NSString *)pathToPDFDirectory;

/**
 Selects the restaraunt name from the parameters major and minor beacon.
 @param majorBeacon The Major number of the closest beacon.
 @param minorBeacon The Minor number of the closest beacon.
 @return The name of the restaraunt.
 */
-(NSString *)requestRestaurantNameForMajorBeacon:(NSNumber *)majorBeacon andMinorBeacon:(NSNumber *)minorBeacon;

#pragma mark - fakeituntilyoumakeit
/**
    Returns 1 recipe for every category inside the local database
 */
-(NSMutableArray *)bestMatchForRecipe:(NSString *)recipeSlug;

/**
 Close database connection when the application closes
 */
-(void)closeDatabaseConnection;

@end
