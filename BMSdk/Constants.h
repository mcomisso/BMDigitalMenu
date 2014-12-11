//
//  Constants.h
//  BMSdk
//
//  Created by Matteo Comisso on 22/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#ifndef BMSdk_Constants_h
#define BMSdk_Constants_h

#define IS_IPHONE4          (([[UIScreen mainScreen] bounds].size.height-480)?NO:YES)
#define IS_IPHONE5          (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_OS_5_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#endif

// Definition Bluemate Api
#define BMAPI_RECIPES_FROM_MAJ_MIN      @"https://bmbackend-misiedo.appspot.com/api/recipes/majmin/"
#define BMAPI_DAYMENU_FROM_MAJ_MIN      @"https://bmbackend-misiedo.appspot.com/api/daymenu/majmin/"

#define BMAPI_RECIPE_DETAILS_FROM_SLUG  @"https://bmbackend-misiedo.appspot.com/api/recipe/"
#define BMAPI_COMMENTS_FOR_RECIPE_SLUG  @"https://bmbackend-misiedo.appspot.com/api/comments/recipe/"
#define BMAPI_RATING_FOR_RECIPE_SLUG    @"https://bmbackend-misiedo.appspot.com/api/rating/recipe/"

#define BMDarkValueColor        [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1]
#define BMLightDarkValueColor   [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1]