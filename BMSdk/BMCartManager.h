//
//  BMCartManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMCartManager : NSObject

@property (nonatomic, strong) NSMutableArray *selectedRecipes;

+(BMCartManager *)sharedInstance;

-(int)numbersOfItemInCart;

-(NSArray *)itemsInCart;

-(void)addItemInCart:(NSString *)idOfRecipe;

-(void)deleteFromCartWithId:(NSString *)idOfRecipe;

@end
