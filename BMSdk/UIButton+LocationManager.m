//
//  UIButton+LocationManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 27/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "UIButton+LocationManager.h"

@implementation UIButton_LocationManager

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    // Custom drawing methods
    if (self)
    {
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(enableButton)
                                                    name:@"enableButton"
                                                  object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(disableButton)
                                                    name:@"disableButton"
                                                  object:nil];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(enableButton)
                                                    name:@"enableButton"
                                                  object:nil];

        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(disableButton)
                                                    name:@"disableButton"
                                                  object:nil];
    }
    return self;
}

-(void)enableButton
{
    NSLog(@"Notification received");
    [self setEnabled:YES];
}

-(void)disableButton
{
    NSLog(@"Notification received");
    [self setEnabled:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
