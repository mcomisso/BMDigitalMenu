//
//  BMDataManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 05/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMDataManager.h"
@import UIKit;
@import CoreData;

@interface BMDataManager()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation BMDataManager

+(BMDataManager *)sharedInstance
{
    static BMDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}

-(id)initUniqueInstance
{
    self = [super init];
    
    if (self != nil)
    {
    }
    
    return self;
}

-(void)storeData:(NSDictionary)dictionary
{
    self.managedObjectContext
}

@end
