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
#pragma mark - Save Methods
/**
 Saves the latest fetched menu into the SQLite DataBase
 @param JSONArray json containing all the recipes of a particular restaraunt
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
 @param restaraunt The id of the restaraunt
 */
-(void)savePDFUuid:(NSString *)pdfUUID ofRestaraunt:(NSString *)restaraunt;

#pragma mark - Check Methods
/**
 Interrogates the database to fetch all the data of a particular restaraunt. Policy: Cache first, then Network if available.
 @param restarauntId The major number of the beacons inside a restaraunt.
 @return The date in string format of the latest recipe inside the database.
 */
-(NSString *)latestMenuEntryOfRestaraunt:(NSString *)restarauntId;

/**
 Interrogates the existing database to determine if should download data
 @param idRecipe The unique ID of a recipe
 @return BOOL YES or NO
 */
-(BOOL)shouldFetchCommentsFromServer:(NSString*)idRecipe;

#pragma mark - Data Request Methods
/**
 Interrogates the database to fetch all and only the categories for the given restarauntMajorNumber

 @param restarauntMajorNumber The major number of a certain restaraunt.
 
 */
-(NSArray *)requestCategoriesForRestaraunt:(NSNumber *)restarauntMajorNumber;

/**
 Interrogates the database to fetch all the data of a particular category. Policy: Only cache.
 
 @param category The category wanted to show.
 @param restarauntId The identification number of the restaraunt
 
 */
-(NSArray *)requestRecipesForCategory:(NSString *)category ofRestaraunt:(NSString *)restarauntID;

/**
 Interrogates the database to fetch all the data of a particular recipe. Policy: Only cache. Images are handled as multimedia with SDImageView.
 
 @param idRecipe The unique ID of a recipe.
 @param restarauntID The identification number of the restaraunt
 
 */
-(NSMutableDictionary*)requestDetailsForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restarauntID;

/**
 Interrogates the existing database to fetch the rating of a particular recipe. Returns nil if there's no data to show.

 @param idRecipe The unique ID of a recipe.
 @param restarauntID The identification number of the restaraunt
 
 */
-(int)requestRatingForRecipe:(NSString *)idRecipe;

/**
 Interrogates the existing database to fetch all the ratings for the selected categories.
 @param category The category "searched"
 @return A dictionary with key value as recipeID and value as average count of rating
 */
-(NSDictionary *)requestRatingForRecipesInCategory:(NSString *)category;

/**
 Interrogates the existing database to fetch the comments for a particular recipe. Returns nil if there's no data to show.

 @param idRecipe The unique ID of a recipe.
 @return Array containing all the comments available
 */
-(NSArray *)requestCommentsForRecipe:(NSString *)idRecipe;

/**
 Fetch all data for recipes inserted in "cart"

 @param listOfRecipesToFind Array containing the id's of recipes to find inside the database
 @return array containing all the detailed recipes
 */
-(NSMutableArray *)requestDataForCart:(NSArray*)listOfRecipesToFind;

#pragma mark - Delete from menu

/**
 Deletes all recipes for a partcular restaraunt
 @param restarauntId Id of restaraunt, which recipes will be deleted.
 */
-(void)deleteDataFromRestaraunt:(NSString *)restarauntId;

/**
 Deletes all comments for a particular recipe
 @param idRecipe ID for a particular recipe.
 */
-(void)deleteCommentsOfRecipe:(NSString *)idRecipe;

/**
 Counts the numbers of recipes currently inside the database.
 @return COUNT(*) of recipes
 */
-(int)numberOfrecipesInCache;

#pragma mark - PDF utils

/**
 Controls if the PDF directory exists. If not, the method creates one.
 */
-(NSString *)pathToPDFDirectory;

/**
 Selects from the database the name of the pdf for a particular restarauntID
 @param restarauntId The ID of the restaraunt
 @return The UUID of the pdf for the selected restarauntId
 */
-(NSString *)requestPDFNameOfRestaraunt:(NSString *)restarauntId;


#pragma mark - fakeituntilyoumakeit
/**
    Returns 1 recipe for every category inside the local database
 */
-(NSMutableArray *)bestMatchForRecipe:(NSString *)idRecipe;

@end
