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
 
 */
-(void)fetchDataOfRestaraunt:(NSNumber *)majorNumber;

@end
