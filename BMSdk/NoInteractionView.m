//
//  NoInteractionView.m
//  BMSdk
//
//  Created by Matteo Comisso on 18/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "NoInteractionView.h"

@implementation NoInteractionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    else
    {
        return hitView;
    }
}

@end
