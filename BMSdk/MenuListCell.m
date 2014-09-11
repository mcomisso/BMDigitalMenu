//
//  MenuListCell.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "MenuListCell.h"

@interface MenuListCell()

@property (nonatomic) CGPoint whiteViewCenter;

@end

@implementation MenuListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // init stars
        UIView *whiteView =(UIView *)[self.contentView viewWithTag:114];
        self.whiteViewCenter = whiteView.center;
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    self.canWhiteViewBeMovedLeft = NO;
    self.canWhiteViewBeMovedRight = YES;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(UIImage *)imageColoredGenerator
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    UIColor *color = [[UIColor alloc]initWithCGColor:[UIColor whiteColor].CGColor];
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)prepareForReuse
{
    self.canWhiteViewBeMovedLeft = NO;
    self.canWhiteViewBeMovedRight = YES;

    UIView *whiteView = (UIView *)[self.contentView viewWithTag:114];
    whiteView.center = self.whiteViewCenter;
    
    AXRatingView *axrate = (AXRatingView *)[self.rateViewContainer viewWithTag:114];
    [axrate removeFromSuperview];
 
    UIImageView *imag = (UIImageView *)[self.recipeImage viewWithTag:110];
    imag.image = [self imageColoredGenerator];

    [super prepareForReuse];
}

@end
