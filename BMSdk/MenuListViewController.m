//
//  MenuListViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "MenuListViewController.h"
#import "MenuListCell.h"
#import "NoImageTableViewCell.h"

#import "BMDataManager.h"
#import "BMUsageStatisticManager.h"

#import "RecipeDetailViewController.h"

//Cell related
#import "UIImageView+WebCache.h"
#import "AFNetworking.h"
#import "AXRatingView.h"

#define BMIMAGEAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"
#define BMRATEAPI @"http://54.76.193.225/api/v1/client/vote/"

@interface MenuListViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *recipesInCategory;

@property (strong, nonatomic) NSMutableDictionary *ratingForRecipe;

@property (strong, nonatomic) BMDataManager *dataManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;

//Testing purpose variables
@property (nonatomic) BOOL ratingDownloaded;

@end

@implementation MenuListViewController

#pragma mark - Color Utils
-(UIColor *)BMDarkValueColor
{
    return [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
}

#pragma mark - Initialization View methods
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
    
    self.dataManager = [BMDataManager sharedInstance];
    self.statsManager = [BMUsageStatisticManager sharedInstance];

    [self setPreferredToolbar];
    
    [self loadRecipesForCategory];

    [self loadSwipeGestureRecognizer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:NO];
}

/**
 Sets the colors of the navigation and tool bar
 */
-(void)setPreferredToolbar
{
    self.tableView.scrollsToTop = YES;
    self.title = [self.category uppercaseString];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [self BMDarkValueColor];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [self BMDarkValueColor]}];
    
//    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = NO;
}

-(void)loadSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleSwipeLeft:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.tableView addGestureRecognizer:recognizer];
    
    //Add a right swipe gesture recognizer
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(handleSwipeRight:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:recognizer];
}

/**
 Handlers for swiping left/right the content inside the UITableViewCell
 */
- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer
{
    //Get location of the swipe
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    
    //Get the corresponding index path within the table view
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    //Check if index path is valid
    if(indexPath)
    {
        if ([[self.tableView cellForRowAtIndexPath:indexPath]isKindOfClass:[MenuListCell class]]) {
            MenuListCell *cell = (MenuListCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            UIView *whiteView = (UIView *)[cell.contentView viewWithTag:115];
            
            if (cell.canWhiteViewBeMovedLeft) {
                CGPoint originalCenter = whiteView.center;
                whiteView.alpha = 0.f;
                [UIView animateWithDuration:0.3 delay:0.f usingSpringWithDamping:2.f initialSpringVelocity:6.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    whiteView.alpha = 1;
                    whiteView.center = CGPointMake(originalCenter.x - 210, originalCenter.y);
                } completion:^(BOOL finished) {
                    NSLog(@"End animation");
                    cell.canWhiteViewBeMovedRight = YES;
                    cell.canWhiteViewBeMovedLeft = NO;
                }];
            }
        }
        
        //Get the cell out of the table view
        //        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        //Update the cell or model
        //        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath) {
        if ([[self.tableView cellForRowAtIndexPath:indexPath]isKindOfClass:[MenuListCell class]]) {
            MenuListCell *cell = (MenuListCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            UIView *whiteView = (UIView *)[cell.contentView viewWithTag:115];

            if (cell.canWhiteViewBeMovedRight) {
                CGPoint originalCenter = whiteView.center;
                
                [UIView animateWithDuration:0.3 delay:0.f usingSpringWithDamping:2.f initialSpringVelocity:6.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    whiteView.center = CGPointMake(originalCenter.x + 210, originalCenter.y);
                } completion:^(BOOL finished) {
                    NSLog(@"End animation");
                    cell.canWhiteViewBeMovedRight = NO;
                    cell.canWhiteViewBeMovedLeft = YES;
                }];
            }
        }
    }
}

-(void)loadRecipesForCategory
{
    self.ratingForRecipe = [[NSMutableDictionary alloc]init];
    self.recipesInCategory = [self.dataManager requestRecipesForCategory:self.category ofRestaraunt:@"2"];
    NSLog(@"Array description: %@", [_recipesInCategory description]);

    [self loadRatingForRecipesInThisCategory];
    
    [self.tableView reloadData];
}

-(void)loadRatingForRecipesInThisCategory
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    for (NSDictionary *recipe in self.recipesInCategory)
    {
        NSString *ricetta_id = [recipe objectForKey:@"ricetta_id"];
        
        // Point to vote API for every recipeID inside the Array
        [manager GET:[BMRATEAPI stringByAppendingString:ricetta_id]
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {

                 //Set the pair "AVG Rate" : "Recipe ID"
                 [self.ratingForRecipe setObject:[responseObject objectForKey:@"media"] forKey:ricetta_id];

                 //Save rating value inside database
                 [self.dataManager saveRatingValue:[NSNumber numberWithInt:(int)[[responseObject objectForKey:@"media"]intValue]] forRecipe:ricetta_id];
                 
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                 NSLog(@"Cannot download rating for recipe. Error: %@ %@", [error localizedDescription], [error localizedFailureReason]);

             }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    static NSString *cellIdentifier = @"cellIdentifier";
    static NSString *whiteCellIdentifier = @"whiteCellIdentifier";

    NSDictionary *recipe = [self.recipesInCategory objectAtIndex:indexPath.row];
    //IF RECIPE HAS IMAGE
    if ([[recipe objectForKey:@"immagine"]isEqualToString:@"nil"]) {
        NoImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:whiteCellIdentifier];
        //Setup Cell
        cell.recipeId = [recipe objectForKey:@"ricetta_id"];
        cell.recipeIngredients.text = [recipe objectForKey:@"ingredienti"];
        UILabel *recipeName = (UILabel *)[cell viewWithTag:200];
        recipeName.text = [[recipe objectForKey:@"nome"]uppercaseString];

        UILabel *recipePrice = (UILabel *)[cell viewWithTag:201];
        recipePrice.text = [[@"Prezzo: " stringByAppendingString:[recipe objectForKey:@"prezzo"]]stringByAppendingString:@"€"];

        AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, cell.rateViewContainer.frame.size.height)];
        thisratingView.value = 4.f;
        thisratingView.tag = 114;
        thisratingView.numberOfStar = 5;
        thisratingView.baseColor = [self BMDarkValueColor];
        thisratingView.highlightColor = [UIColor whiteColor];

        thisratingView.userInteractionEnabled = NO;
        thisratingView.stepInterval = 1.f;
        
        [cell.rateViewContainer addSubview:thisratingView];

        return cell;
    }
    else
    {
        MenuListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.recipeId = [recipe objectForKey:@"ricetta_id"];
        
        UILabel *recipeName = (UILabel *)[cell viewWithTag:111];
        recipeName.text = [[recipe objectForKey:@"nome"]uppercaseString];
        
        UILabel *recipePrice = (UILabel *)[cell viewWithTag:112];
        
        recipePrice.text = [[@"Prezzo: " stringByAppendingString:[recipe objectForKey:@"prezzo"]]stringByAppendingString:@"€"];
        
        AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, cell.rateViewContainer.frame.size.height)];
        thisratingView.value = 4.f;
        thisratingView.tag = 114;
        thisratingView.numberOfStar = 5;
        thisratingView.baseColor = [self BMDarkValueColor];
        thisratingView.highlightColor = [UIColor whiteColor];
        
        thisratingView.userInteractionEnabled = NO;
        thisratingView.stepInterval = 1.f;
        
        [cell.rateViewContainer addSubview:thisratingView];
        
        cell.recipeImageUrl = [recipe objectForKey:@"immagine"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.clipsToBounds = YES;

        NSString *downloadString = [BMIMAGEAPI stringByAppendingString:cell.recipeImageUrl];
        
        UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:110];
        recipeImageView.clipsToBounds = YES;
        [recipeImageView  sd_setImageWithURL:[[NSURL alloc]initWithString:downloadString]
                            placeholderImage:[self imageColoredGenerator]
                                     options:SDWebImageRefreshCached];
    
        thisratingView.value = [self.dataManager requestRatingForRecipe:cell.recipeId];

        return cell;
    }
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

/* Deve ritornare il count degli elemeti padre nell NSDictionary */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/* Deve ritornare il numero degli elementi children di un nodo padre */
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recipesInCategory count];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"details"]) {
        RecipeDetailViewController *dvc = (RecipeDetailViewController *)[segue destinationViewController];
        NSDictionary *recipe = [self.recipesInCategory objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        
        dvc.recipeName = [[recipe objectForKey:@"nome"]capitalizedString];
        dvc.recipePrice = [[@"Prezzo: " stringByAppendingString:[recipe objectForKey:@"prezzo"]]stringByAppendingString:@"€"];
        dvc.recipeImageUrl = [recipe objectForKey:@"immagine"];
        dvc.recipeId = [recipe objectForKey:@"ricetta_id"];

    }
}

@end
