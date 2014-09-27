//
//  BMCartManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//
/*
 DESCRIPTION:
 SingletonClass.
 La classe BMCartManager implementa un modo per salvare la lista di piatti preferiti dall'utente.
 L'idea è quella di fornire al consumatore un modo per salvare le proprie portate e successivamente ordinarle vocalmente al cameriere, quindi non verrà mantenuta traccia in memoria. I dati dei piatti "salvati per dopo" verranno prelevati dalla classe BMUsageStatisticManager
 */

#import <Foundation/Foundation.h>

@interface BMCartManager : NSObject

@property (nonatomic, strong) NSMutableArray *selectedRecipes;

/**
 Cart manager initial instance
 */
+(BMCartManager *)sharedInstance;

/**
 Numbers of items currently saved inside cart
 @return Int number
 */
-(int)numbersOfItemInCart;

/**
 Returns an array with the items saved inside cart
 @return Array with items
 */
-(NSArray *)itemsInCart;

/**
 Adds an item inside the cart
 @param idOfRecipe id of recipe to add
 */
-(void)addItemInCart:(NSString *)idOfRecipe;

/**
 Removes an item from the cart
 @param idOfRecipe id of recipe to be deleted
 */
-(void)deleteFromCartWithId:(NSString *)idOfRecipe;

/**
 Checks inside the current array if the wanted recipe exists
 @param idOfRecipe id of recipe to check
 */
-(BOOL)isRecipeSavedInCart:(NSString *)idOfRecipe;

@end
