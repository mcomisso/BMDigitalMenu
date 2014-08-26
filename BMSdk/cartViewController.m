//
//  cartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "cartViewController.h"
#import "MenuListCell.h"

#import "BMCartManager.h"

@interface cartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) BMCartManager *cartManager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *dataSource;

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
 
    self.cartManager = [BMCartManager sharedInstance];
    
    self.dataSource = [[NSArray alloc]initWithArray:[self.cartManager itemsInCart] copyItems:NO];
    
    [self setBackGesture];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - tableView methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSDictionary *recipe = [self.dataSource objectAtIndex:indexPath.row];
    
    static NSString *cellIdentifier = @"cellIdentifier";
    MenuListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[MenuListCell alloc]initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];
    }
    cell.recipeId = [recipe objectForKey:@"id"];
    cell.recipeImage = [recipe objectForKey:@"image"];
    cell.recipePrice = [recipe objectForKey:@"price"];
    cell.recipeTitle = [recipe objectForKey:@"title"];

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 
    NSLog(@"Description: %@", [self.dataSource description]);
   return [self.dataSource count];

}

-(void)reloadDataFromCart
{
    self.dataSource = [[NSArray alloc]initWithArray:[self.cartManager itemsInCart] copyItems:YES];
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
