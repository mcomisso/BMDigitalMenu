//
//  BMCartManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMCartManager.h"
#import "BMDataManager.h"

@interface BMCartManager()

@end

@implementation BMCartManager

+(BMCartManager *)sharedInstance
{
    static BMCartManager *sharedInstance = nil;
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
        NSLog(@"[Cart Manager] BMDownload Manager initialized");
        self.selectedRecipes = [[NSMutableArray alloc]init];
    }
    return self;
}

-(int)numbersOfItemInCart
{
    return (int)self.selectedRecipes.count;
}

-(NSArray *)itemsInCart
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    NSArray *retval = [dataManager requestDataForCart:self.selectedRecipes];
    return retval;
}

-(void)addItemInCart:(NSString *)idOfRecipe
{
    NSLog(@"[CartManager]ID recipe %@", idOfRecipe);
    NSLog(@"[Cartmanager]Description %@", [self.selectedRecipes description]);
    [self.selectedRecipes addObject:idOfRecipe];
}

-(void)deleteFromCartWithId:(NSString *)idOfRecipe
{
    [self.selectedRecipes removeObjectAtIndex:[self.selectedRecipes indexOfObject:idOfRecipe]];
}

@end
