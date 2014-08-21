//
//  RecipeDetailViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RecipeDetailViewController.h"
#import "ModalBlurredSegue.h"
#import "BMDataManager.h"

@interface RecipeDetailViewController () <UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) IBOutlet UILabel *recipeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipePriceLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipeIngredientsLabel;
@property (strong, nonatomic) IBOutlet UITextView *ingredientsText;
@property (strong, nonatomic) IBOutlet UILabel *recipeDescriptionLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionText;

@property (strong, nonatomic) NSMutableDictionary *recipeDetails;

@end

@implementation RecipeDetailViewController

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
    //return to previous view
    UIScreenEdgePanGestureRecognizer *sepg = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(pop)];
    sepg.delegate = self;
    [sepg setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:sepg];
    
    [self loadRecipeData];
    
}

-(void)loadRecipeData
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    [[NSUserDefaults standardUserDefaults]objectForKey:@""];

    self.recipeDetails = [dataManager requestDetailsForRecipe:self.recipeId ofRestaraunt:@"0"];
    
    self.recipeNameLabel.text = self.recipeName;
    self.recipePriceLabel.text = self.recipePrice;
    self.ingredientsText.text = [self.recipeDetails objectForKey:@"ingredienti"];
    self.descriptionText.text = [self.recipeDetails objectForKey:@"descrizione"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - bar actions

/* Condividi il piatto sui social networks */
- (IBAction)share:(id)sender {
    
}

/* Carica i commenti */
- (IBAction)viewComments:(id)sender {
    
}

/* Vota il piatto corrente */
- (IBAction)rateRecipe:(id)sender {
    
}

/* Accostamenti fattibili */
- (IBAction)loadCombinations:(id)sender {
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

-(void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
