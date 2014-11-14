//
//  RecipeInfo.m
//  BMSdk
//
//  Created by Matteo Comisso on 13/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RecipeInfo.h"

@implementation RecipeInfo

-(NSString *)description
{
    return [NSString stringWithFormat:@"<RecipeInfo: Name %@, Slug: %@>", self.name, self.slug];
}

@end
