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
//#define IS_IPHONE6          (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
//#define IS_IPHONE6PLUS      (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_OS_5_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#endif
