//
//  singleCommentTableViewCell.h
//  BMSdk
//
//  Created by Matteo Comisso on 21/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface singleCommentTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextView *textOfComment;
@property (strong, nonatomic) IBOutlet UILabel *usernameOfCommenter;

@end
