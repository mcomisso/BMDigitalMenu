//
//  BMDownloadManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

/*
    DESCRIPTION of Class:
    BMDownload Manager Should fetch and store all the data requested by the application to gather informations about restaraunt and its recipes.
    Once done, permits to unlock the view.
 
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
 Downloads all the menu for a particular restaraunt, identified by its majornumber
 @param majorNumber The major number of the beacons for a particular restaraunt
 */
-(void)fetchDataOfRestaraunt:(NSNumber *)majorNumber;

/**
 Downloads all the comments for a particular recipe.
 @param idRecipe The id of the selected recipe.
 */
-(void)fetchCommentsForRecipe:(NSString *)idRecipe;

/**
 Downloads the rating for a particular recipe.
 @param idRecipe The id of the selected recipe.
 
 */
-(void)fetchRatingForRecipe:(NSString *)idRecipe;

/**
 
 */
-(void)fetchMenuOfRestaraunt:(NSNumber *)restarauntMajorNumber;

@end
