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

@interface CommentsModalViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *dataSourceOfComments;
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
    // Do any additional setup after loading the view.
    
    //Load Comments from database
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    self.dataSourceOfComments = [dataManager fetchCommentsForRecipe:self.idRecipe ofRestaraunt:@"0"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    singleCommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[singleCommentTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textOfComment.text = [self.dataSourceOfComments[indexPath.row] objectForKey:@"comment"];
    cell.usernameOfCommenter.text = [self.dataSourceOfComments[indexPath.row] objectForKey:@"user"];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSourceOfComments count];
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
