//
//  BMDataManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 05/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMDataManager : NSObject

+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));

/**
 Creates and returns an `BMDataManager` object. Instantiate this object only through this class method.
 */
+(BMDataManager *)sharedInstance;

/**
 Saves the latest fetched menu into the SQLite DataBase
 */
-(void)saveMenuData:(NSArray *)JSONArray;

/**
 Interrogates the database to fetch all the data of a particular restaraunt. Policy: Cache first, then Network if available.
 
 @param restarauntMajorNumber The major number of the beacons inside a restaraunt.
 
 */
-(void)requestDataForRestaraunt:(NSNumber*)restarauntMajorNumber;

/**
 Interrogates the database to fetch all and only the categories for the given restarauntMajorNumber
 */
-(NSArray *)requestCategoriesForRestaraunt:(NSNumber *)restarauntMajorNumber;

/**
 Interrogates the database to fetch all the data of a particular category. Policy: Only cache.
 
 @param category The category wanted to show.
 
 */
-(NSArray *)requestDataForCategory:(NSString *)category ofRestaraunt:(NSString *)restarauntID;

/**
 Interrogates the database to fetch all the data of a particular recipe. Policy: Only cache. Images are handled as multimedia with SDImageView.
 
 @param idRecipe The unique ID of a recipe.
 
 */
-(void)requestDetailsForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt;

/**
 Interrogates the existing database to fetch the rating of a particular recipe. Returns nil if there's no data to show.
 */
-(NSNumber *)fetchRatingForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt;

/**
 Interrogates the existing database to fetch the comments for a particular recipe. Returns nil if there's no data to show.
 */
-(NSDictionary *)fetchCommentsForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt;

@end
