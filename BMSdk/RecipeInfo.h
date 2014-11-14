//
//  RecipeInfo.h
//  BMSdk
//
//  Created by Matteo Comisso on 13/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//
/*
 DESCRIPTION:
 Incapsula la struttura dati di una ricetta.
 */

#import <Foundation/Foundation.h>

@interface RecipeInfo : NSObject

@property NSString *name;
@property NSNumber *price;
@property NSString *category;
@property NSDate *last_edit_datetime;
@property NSString *image_url;
@property NSString *recipe_description;
@property NSString *ingredients;
@property NSString *slug;
@property NSArray *best_match;


@end
