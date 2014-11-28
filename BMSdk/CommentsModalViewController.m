//
//  CommentsModalViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 17/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//
#import "singleCommentTableViewCell.h"
#import "CommentsModalViewController.h"
#import "BMDataManager.h"
#import "BMUsageStatisticManager.h"

@interface CommentsModalViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *dataSourceOfComments;

//Background
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UILabel *noCommentsLabel;

@property (strong, nonatomic) BMUsageStatisticManager *statsManager;
@end

@implementation CommentsModalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statsManager = [BMUsageStatisticManager sharedInstance];

    // Do any additional setup after loading the view.
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];

    //Load Comments from database
    BMDataManager *dataManager = [BMDataManager sharedInstance];
//    self.dataSourceOfComments = [NSArray arrayWithObject:@"Nessun commento ancora inserito."];
    self.dataSourceOfComments = [NSArray arrayWithArray:[dataManager requestCommentsForRecipe:self.idRecipe]];

    [self editViewIfNoRecipes];
}

/**
 Checks if there's comments for the selected recipe. If not, removes the tableview and shows the label.
 */
-(void)editViewIfNoRecipes
{
    if ([self.dataSourceOfComments count] == 0) {
        self.tableView.alpha = 0.f;
    }
    else
    {
        self.noCommentsLabel.alpha = 0.f;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self basicCellAtIndexPath:indexPath];
}

-(singleCommentTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    singleCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureBasicCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)configureBasicCell:(singleCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *recipe = self.dataSourceOfComments[indexPath.row];
    [self setUsernameForCell:cell item:recipe];
    [self setCommentForCell:cell item:recipe];
}

-(void)setUsernameForCell:(singleCommentTableViewCell *)cell item:(NSDictionary*)item
{
    NSNumber *usernameID = [item objectForKey:@"user"];
    NSString *string = [NSString stringWithFormat:@"Utente id: %@", usernameID];
    [cell.usernameLabel setText:string];
}

-(void)setCommentForCell:(singleCommentTableViewCell *)cell item:(NSDictionary *)item
{
    NSString *string = [item objectForKey:@"comment"];
    [cell.commentLabel setText:string];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

-(CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    static singleCommentTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    });
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

-(CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSourceOfComments count];
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Gesture recognizer


@end