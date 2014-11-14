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
    int numbersOfItems = 0;
    if (_selectedRecipes == nil) {
        return numbersOfItems;
    }
    else
    {
        numbersOfItems = (int)[self.selectedRecipes count];
        return numbersOfItems;
    }

}

-(NSArray *)itemsInCart
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    NSArray *retval = [dataManager requestDataForCart:self.selectedRecipes];
    return retval;
}

-(void)addItemInCart:(NSString *)recipeSlug
{
    NSLog(@"[CartManager]ID recipe %@", recipeSlug);
    NSLog(@"[Cartmanager]Description %@", [self.selectedRecipes description]);
    [self.selectedRecipes addObject:recipeSlug];
}

-(void)deleteFromCartWithSlug:(NSString *)recipeSlug
{
    [self.selectedRecipes removeObjectAtIndex:[self.selectedRecipes indexOfObject:recipeSlug]];
}

-(BOOL)isRecipeSavedInCart:(NSString *)recipeSlug
{
    NSLog(@"[CartManager] ID recipe to check %@", recipeSlug);
    if ([self.selectedRecipes containsObject:recipeSlug]) {
        return YES;
    }
    else
    {
        return NO;
    }
    
}

@end
