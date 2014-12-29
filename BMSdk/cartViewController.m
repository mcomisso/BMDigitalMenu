//
//  cartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "cartViewController.h"
#import "cartTableViewCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "BMCartManager.h"
#import "BMUsageStatisticManager.h"

#import "RecipeInfo.h"

@interface cartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataSource;

@property (weak, nonatomic) IBOutlet UIButton *reminderButton;

@property (weak, nonatomic) IBOutlet UILabel *noContentLabel;
@property (weak, nonatomic) IBOutlet UILabel *helpMessageLabel;
@end

@implementation cartViewController

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
    // Do any additional setup after loading the view.
    //[self setNeedsStatusBarAppearanceUpdate];
    
    self.cartManager = [BMCartManager sharedInstance];
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    self.dataSource = [[NSMutableArray alloc] initWithArray:[self.cartManager itemsInCart]];

    [self setupViewIfEmptyArray];
    
    [self setPreferredToolbar];
    
    [self localizeView];
    
    /*CONFIGURATION OF BUTTON*/
    self.reminderButton.layer.cornerRadius = self.reminderButton.frame.size.width/2;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tableView.editing=false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)localizeView
{
    self.noContentLabel.text = BMLocalizedString(@"NoContent", nil);
    self.helpMessageLabel.text = BMLocalizedString(@"NoContentMessage", nil);
    
}

-(void)setupViewIfEmptyArray
{
    if ([self.dataSource count] == 0) {
        self.tableView.alpha = 0;
    }
}

-(void)setPreferredToolbar
{
    self.tableView.scrollsToTop = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = NO;
}

#pragma mark - tableView methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    RecipeInfo *recipe = [self.dataSource objectAtIndex:indexPath.row];
    
    cartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[cartTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];
    }
    cell.recipeSlug = recipe.slug;
    DLog(@"Recipe Description: %@", [recipe description]);
    
    // SD_IMAGE to set the image in async
    [cell.recipeImageView sd_setImageWithURL:[NSURL URLWithString:recipe.image_url]
                            placeholderImage:[self generateWhiteImage]];

    cell.recipeImageView.clipsToBounds = YES;

    // Set the strings for the labels
    cell.recipePrice.text = [[NSString stringWithFormat:@"%@",recipe.price] stringByAppendingString:@"€"];
    
    cell.recipeName.text = recipe.name;

    cell.recipeCategory.text = [recipe.category capitalizedString];
    return cell;
}

#pragma mark - Delete Methods
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [UIView animateWithDuration:0.2f animations:^{
        self.reminderButton.center = CGPointMake(self.reminderButton.center.x, self.reminderButton.center.y + 100);
    }];
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [UIView animateWithDuration:0.2f animations:^{
        self.reminderButton.center = CGPointMake(self.reminderButton.center.x, self.reminderButton.center.y - 100);
    }];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Delete from source + remove from view
        
        [self.dataSource removeObjectAtIndex:indexPath.row];
        
        cartTableViewCell *cell = (cartTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];

        [self.cartManager deleteFromCartWithSlug:cell.recipeSlug];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
        if ([self.dataSource count] == 0) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.tableView.alpha = 0.f;
                             }];
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 
    DLog(@"Description: %@", [self.dataSource description]);
   return [self.dataSource count];
}

#pragma mark - Scrollview delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.reminderButton.alpha = 0.3f;
                     }];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.reminderButton.alpha = 1.f;
                     }];
}

#pragma mark - Utils
-(void)reloadDataFromCart
{
    self.dataSource = [[NSMutableArray alloc]initWithArray:[self.cartManager itemsInCart]];
}

-(UIImage *)generateWhiteImage
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
