//
//  MenuListViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "MenuListViewController.h"
#import "MenuListCell.h"
#import "BMDataManager.h"
#import "RecipeDetailViewController.h"

#import "UIImageView+WebCache.h"

#import "AFNetworking.h"

#import "FBShimmering.h"
#import "AXRatingView.h"

#define BMIMAGEAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"
#define BMRATEAPI @"http://54.76.193.225/api/v1/client/vote/"

@interface MenuListViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *recipesInCategory;

//Testing purpose variables
@property (nonatomic, strong) NSArray *testingArray;

@end

@implementation MenuListViewController

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

    //Scroll to top gesture
    self.tableView.scrollsToTop = YES;
    self.title = [self.category uppercaseString];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    self.view.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
    
    self.navigationItem.hidesBackButton = YES;
    [self setBackGesture];
    
    [self loadRecipesForCategory];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:NO];
}

-(void)setBackGesture
{
    UIScreenEdgePanGestureRecognizer *sepg = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(customPopViewController)];
    sepg.delegate = self;
    [sepg setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:sepg];
}

-(void)customPopViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)loadRecipesForCategory
{
    BMDataManager *dataManger = [BMDataManager sharedInstance];
    self.recipesInCategory = [dataManger requestRecipesForCategory:self.category ofRestaraunt:@"2"];
    NSLog(@"Array description: %@", [_recipesInCategory description]);
    [self.tableView reloadData];
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

    NSDictionary *recipe = [self.recipesInCategory objectAtIndex:indexPath.row];
    
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
    thisratingView.baseColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
    thisratingView.highlightColor = [UIColor whiteColor];
    
    thisratingView.userInteractionEnabled = NO;
    thisratingView.stepInterval = 1.f;

    [cell.rateViewContainer addSubview:thisratingView];

    cell.recipeImageUrl = [recipe objectForKey:@"immagine"];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.clipsToBounds = YES;


    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];

    [manager GET:[BMRATEAPI stringByAppendingString:cell.recipeId]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             int value = [[responseObject objectForKey:@"media"]intValue];
             thisratingView.value = value;
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error while giving rate to cells: %@ %@", [error localizedDescription], [error localizedFailureReason]);
         }];
    /*
    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:shimmeringView];
    
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:shimmeringView.bounds];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text = NSLocalizedString(@"Shimmer", nil);
    shimmeringView.contentView = loadingLabel;
    
    // Start shimmering.
    shimmeringView.shimmering = YES;*/
    
    return cell;
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(MenuListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:110];

    NSString *downloadString = [BMIMAGEAPI stringByAppendingString:cell.recipeImageUrl];
    if (![downloadString isEqualToString:[BMIMAGEAPI stringByAppendingString:@"nil"]]) {

        cell.recipeTitle.frame = CGRectMake(168, 10, 142, 45);
        cell.recipePrice.frame = CGRectMake(168, 62, 132, 21);
        
        [recipeImageView  sd_setImageWithURL:[[NSURL alloc]initWithString:downloadString] placeholderImage:[self imageColoredGenerator] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                NSLog(@"Error! %@ %@", [error localizedDescription], [error localizedFailureReason]);
            }
        }];
    }
    else
    {
        cell.recipeTitle.frame = CGRectMake(10, 10, 320, 45);
        cell.recipePrice.frame = CGRectMake(10, 91, 132, 21);
    }
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
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
