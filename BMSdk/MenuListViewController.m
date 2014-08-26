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
#define BMIMAGEAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"

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
    
    MenuListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[MenuListCell alloc]initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *recipe = [self.recipesInCategory objectAtIndex:indexPath.row];
    
    cell.recipeId = [recipe objectForKey:@"ricetta_id"];
    
    cell.recipeTitle.text = [recipe objectForKey:@"nome"];
    cell.recipePrice.text = [[@"Prezzo: " stringByAppendingString:[recipe objectForKey:@"prezzo"]]stringByAppendingString:@"€"];
//    RateView *ratevw = nil;
    cell.rating = [RateView rateViewWithRating:2.5f];
    cell.rating.tag = 88888;
    cell.rating.starSize = 30;
    cell.recipeImageUrl = [recipe objectForKey:@"immagine"];
    NSString *downloadString = [BMIMAGEAPI stringByAppendingString:cell.recipeImageUrl];
    [cell.recipeImage  sd_setImageWithURL:[[NSURL alloc]initWithString:downloadString]];

    return cell;
}

/* Deve ritornare il count degli elemeti padre nell NSDictionary */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 80)];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:12]];
    [label setText:@"PRIMI PIATTI"];
    
    label.textColor = [UIColor whiteColor];
    view.backgroundColor = [UIColor blackColor];
    
    [view addSubview:label];
    
    return view;
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
        MenuListCell *cell = (MenuListCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        dvc.recipeName = cell.recipeTitle.text;
        dvc.recipePrice = cell.recipePrice.text;
        dvc.recipeImage = cell.recipeImage.image;
        dvc.recipeId = cell.recipeId;
    }
}

@end
