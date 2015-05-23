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

#import "AFBMNetworkReachabilityManager.h"

#import "RecipeDetailViewController.h"
#import "RecipeInfo.h"

//Cell related
#import "UIImageView+WebCache.h"
#import "AFBMNetworking.h"
#import "AXRatingView.h"

#import "Constants.h"
#import "UAObfuscatedString.h"

#define LEFTMARGIN 110

@interface MenuListViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *recipesInCategory;

@property (strong, nonatomic) NSMutableDictionary *ratingForRecipe;

@property (strong, nonatomic) BMDataManager *dataManager;
@property (strong, nonatomic) AFBMHTTPRequestOperationManager *requestOperationManager;

//Testing purpose variables
@property (nonatomic) BOOL ratingDownloaded;


//Test full list of recipes in sections
@property (strong, nonatomic) NSMutableDictionary *allListOfRecipes;
@end

@implementation MenuListViewController

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
    self.requestOperationManager = [AFBMHTTPRequestOperationManager manager];
    
    _requestOperationManager.requestSerializer = [AFBMHTTPRequestSerializer serializer];

    NSString *user = Obfuscate.c.l.i.e.n.t;
    NSString *password = Obfuscate.p.a.s.s.w.o.r.d;
    
    [_requestOperationManager.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];

    [self setPreferredToolbar];
    [self loadRecipesForCategory];
    [self loadSwipeGestureRecognizer];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
    self.navigationController.navigationBar.tintColor = BMDarkValueColor;
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName :  BMDarkValueColor}];
    
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
            
            if (cell.whiteViewContainer.frame.origin.x >= cell.frame.size.width) {
                CGPoint originalCenter = whiteView.center;
                whiteView.alpha = 0.f;
                [UIView animateWithDuration:0.3 delay:0.f usingSpringWithDamping:2.f initialSpringVelocity:6.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    whiteView.alpha = 1;
                    whiteView.center = CGPointMake(originalCenter.x - whiteView.frame.size.width, originalCenter.y);
                } completion:^(BOOL finished) {
                }];
            }
        }
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

            if (cell.whiteViewContainer.frame.origin.x == LEFTMARGIN) {
                CGPoint originalCenter = whiteView.center;
                
                [UIView animateWithDuration:0.3 delay:0.f usingSpringWithDamping:2.f initialSpringVelocity:6.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    whiteView.center = CGPointMake(originalCenter.x + whiteView.frame.size.width, originalCenter.y);
                } completion:^(BOOL finished) {
                }];
            }
        }
    }
}

-(void)loadRecipesForCategory
{
    NSNumber *majorBeacon = [[NSUserDefaults standardUserDefaults]objectForKey:@"majorBeacon"];
    NSNumber *minorBeacon = [[NSUserDefaults standardUserDefaults]objectForKey:@"minorBeacon"];
    
    self.ratingForRecipe = [[NSMutableDictionary alloc]init];
    self.recipesInCategory = [self.dataManager requestRecipesForCategory:self.category ofRestaurantMajorNUmber:majorBeacon andMinorNumber:minorBeacon];
    DLog(@"Array description: %@", [_recipesInCategory description]);

    [self loadRatingForRecipesInThisCategory];
    
    [self.tableView reloadData];
}

-(void)loadRatingForRecipesInThisCategory
{
    //TODO: Test reachability manager
    if (true) {
        for (RecipeInfo *recipe in self.recipesInCategory)
        {
            // Point to vote API for every recipeID inside the Array
            [_requestOperationManager GET:[BMAPI_RATING_FOR_RECIPE_SLUG stringByAppendingString:[NSString stringWithFormat:@"%@/?format=json", recipe.slug]]
              parameters:nil
                 success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
                     
                     //Set the pair "AVG Rate" : "Recipe ID"
                     NSNumber *ratingValue = [responseObject objectForKey:@"rating"];

                     if (ratingValue != (id)[NSNull null]) {
                         [self.ratingForRecipe setObject:[responseObject objectForKey:@"rating"] forKey:recipe.slug];
                         [self.dataManager saveRatingValue:ratingValue forRecipe:recipe.slug];
                     }
                 }
                 failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
                     
                     DLog(@"Cannot download rating for recipe. Error: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                     
                 }];
        }
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

    RecipeInfo *recipe = [self.recipesInCategory objectAtIndex:indexPath.row];
    //IF RECIPE DOESN'T HAVE ANY IMAGE
    if ([recipe.image_url isEqualToString:@"nil"]) {
        NoImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:whiteCellIdentifier];
        
        cell.recipeSlug = recipe.slug;
        cell.recipeIngredients.text = recipe.ingredients;
        
        UILabel *recipeName = (UILabel *)[cell viewWithTag:200];
        recipeName.text = [recipe.name uppercaseString];

        UILabel *recipePrice = (UILabel *)[cell viewWithTag:201];
        recipePrice.text = [[NSString stringWithFormat:@"%@",recipe.price] stringByAppendingString:@"€"];

        AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, cell.rateViewContainer.frame.size.height)];
        thisratingView.value = 4.f;
        thisratingView.tag = 114;
        thisratingView.numberOfStar = 5;
        thisratingView.baseColor = BMDarkValueColor;
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
        
        cell.recipeSlug = recipe.slug;
        
        UILabel *recipeName = (UILabel *)[cell viewWithTag:111];
        recipeName.text = [recipe.name uppercaseString];
        
        UILabel *recipePrice = (UILabel *)[cell viewWithTag:112];
        
        recipePrice.text = [[NSString stringWithFormat:@"%@", recipe.price] stringByAppendingString:@"€"];
        
        AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, cell.rateViewContainer.frame.size.height)];
        thisratingView.value = 4.f;
        thisratingView.tag = 114;
        thisratingView.numberOfStar = 5;
        thisratingView.baseColor = BMDarkValueColor;
        thisratingView.highlightColor = [UIColor whiteColor];
        
        thisratingView.userInteractionEnabled = NO;
        thisratingView.stepInterval = 1.f;
        
        [cell.rateViewContainer addSubview:thisratingView];
        
        cell.recipeImageUrl = recipe.image_url;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.clipsToBounds = YES;
        
        UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:110];
        recipeImageView.clipsToBounds = YES;
        [recipeImageView  sd_setImageWithURL:[[NSURL alloc]initWithString:[cell.recipeImageUrl stringByAppendingString:@"=s640-c"]]
                            placeholderImage:[self imageColoredGenerator]
                                     options:SDWebImageRefreshCached];
    
        thisratingView.value = [self.dataManager requestRatingForRecipe:cell.recipeSlug];

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

-(void)scrollToCellWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arrayForCategory = [NSArray arrayWithArray:[self.allListOfRecipes objectForKey:self.category]];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"details"]) {
        RecipeDetailViewController *dvc = (RecipeDetailViewController *)[segue destinationViewController];
        RecipeInfo *recipe = [self.recipesInCategory objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        
        dvc.recipeName = [recipe.name capitalizedString];
        dvc.recipePrice = [[@"Prezzo: " stringByAppendingString:[NSString stringWithFormat:@"%@", recipe.price]]stringByAppendingString:@"€"];
        dvc.recipeImageUrl = recipe.image_url;
        dvc.recipeSlug = recipe.slug;
    }
}

@end
