//
//  MSUserData.m
//  BMSdk
//
//  Created by Matteo Comisso on 02/12/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "MSUserData.h"

@interface MSUserData()

@property (nonatomic, readwrite, strong) NSString *username;

@end

@implementation MSUserData

-(instancetype)init
{
    self = [super init];
    if (self) {
        [[NSUserDefaults standardUserDefaults] objectForKey:@"MiSiedoUsername"];
    }
    return self;
}

@end
