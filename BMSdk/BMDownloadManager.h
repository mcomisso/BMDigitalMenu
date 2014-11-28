//
//  BMDownloadManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

/*
    DESCRIPTION of Class:
 Singleton Class.
 
 BMDownload Manager Should fetch and store all the data requested by the application to gather informations about Restaurant and its recipes.
 
 */

#import <Foundation/Foundation.h>
#import "BMDataManager.h"

@interface BMDownloadManager : NSObject

@property (nonatomic, readonly) BOOL isMenuDownloaded;
@property (nonatomic, readonly) NSString *bmUrl;

+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));

/**
 
 */
+(BMDownloadManager *)sharedInstance;

/**
 Downloads all the comments for a particular recipe.
 @param idRecipe The id of the selected recipe.
 */
-(void)fetchCommentsForRecipe:(NSString *)recipeSlug;

/**
 Downloads the rating for a particular recipe.
 @param recipeSlug The id of the selected recipe.
 */
-(void)fetchRatingForRecipe:(NSString *)recipeSlug;

/**
 Makes a GET request to the bluemate server and downlaods the menu
 @param majorNumber The Restaurant's beacon major number
 @param minorNumber The Restaurant's beacon minor number
 */
-(void)fetchMenuOfRestaurantWithMajor:(NSNumber *)majorNumber andMinor:(NSNumber *)minorNumber;

@end
