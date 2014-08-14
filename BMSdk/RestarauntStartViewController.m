//
//  RestarauntStartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RestarauntStartViewController.h"
#import "RestarauntStartmenuCell.h"
#import "SDWebImage/UIImageView+WebCache.h"

#import "MenuListViewController.h"

@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *restarauntName;
@property (strong, nonatomic) IBOutlet UIView *sliderContainer;

@property (strong, nonatomic) NSArray *testCategorie;

@property BOOL isTesting;

@end

@implementation RestarauntStartViewController

-(void)tester
{
    self.isTesting = YES;
    self.testCategorie = @[@"Antipasti",
                           @"Primi Piatti",
                           @"Secondi Piatti",
                           @"Contorni",
                           @"Bevande",
                           @"Vini",
                           @"Dolci",
                           @"Digestivi"];
    
}

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
    self.restarauntName.layer.cornerRadius = self.restarauntName.frame.size.width / 2;
    
    // Add interactions with views
    
    UIPanGestureRecognizer *pgr = [UIPanGestureRecognizer alloc];
    [self.sliderContainer addGestureRecognizer:pgr];
    
    //TESTER
    [self tester];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Gesture Recognizer Methods

-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint velocity = [panGestureRecognizer velocityInView:self.sliderContainer];
    return fabs(velocity.x) < fabs(velocity.y);
}

-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:_sliderContainer];
    
}

#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    RestarauntStartmenuCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[RestarauntStartmenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSLog(@"netCategories description %@", [self.testCategorie description]);

    cell.categoryLabel.text = [self.testCategorie objectAtIndex:indexPath.row];
    
    if ((indexPath.row % 2) == 1) {
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    else
    {
        cell.backgroundColor = [UIColor blackColor];
    }
    cell.categoryLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selezionato row %@", [indexPath description]);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.testCategorie count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSString *)nameOfSelectedCell
{
    RestarauntStartmenuCell *cell = (RestarauntStartmenuCell *)[self.tableView indexPathForSelectedRow];
    return cell.categoryLabel.text;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showRecipes"])
    {
        MenuListViewController *menuList = [segue destinationViewController];
        menuList.category = [self nameOfSelectedCell];
    }
}


@end
