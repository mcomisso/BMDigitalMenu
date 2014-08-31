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
#import "CommentsModalViewController.h"

#import "UIImageView+WebCache.h"
#define BMIMAGEAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"
//TEST
#import "BMDownloadManager.h"
#import "BMCartManager.h"

@interface RecipeDetailViewController () <UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) IBOutlet UILabel *recipeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipePriceLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipeIngredientsLabel;
@property (strong, nonatomic) IBOutlet UITextView *ingredientsText;
@property (strong, nonatomic) IBOutlet UILabel *recipeDescriptionLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionText;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *rateViewContainer;

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

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //return to previous view
    UIScreenEdgePanGestureRecognizer *sepg = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(pop)];
    sepg.delegate = self;
    [sepg setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:sepg];
    
    //Text bigger
    self.recipeNameLabel.text = [self.recipeNameLabel.text uppercaseString];
    
    [self.rateViewContainer setBackgroundColor:[UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1]];
    
    [self loadRecipeData];
    
    BMDownloadManager *dm = [BMDownloadManager sharedInstance];
    BMDataManager *dataManage = [BMDataManager sharedInstance];
    
    [self testLayerGradient];
    
    
    if ([dataManage shouldFetchCommentsFromServer:self.recipeId]) {
        NSLog(@"[RecipeDetailViewController] Comments not found for recipeID %@, name: %@", self.recipeId, self.recipeName);
        [dm fetchCommentsForRecipe:self.recipeId];
    }
    else
    {
        NSLog(@"[RecipeDetailViewController] Comments found in database");
    }
}

-(void)testLayerGradient
{
    UIColor *topColor = [UIColor colorWithWhite:1 alpha:0];
    UIColor *bottomColor = [UIColor colorWithWhite:1 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0], [NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;

    gradientLayer.frame = self.recipeImageView.frame;
    [self.scrollView.layer insertSublayer:gradientLayer atIndex:0];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)loadRecipeData
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    [[NSUserDefaults standardUserDefaults]objectForKey:@"//RESTARAUNT"];

    self.recipeDetails = [dataManager requestDetailsForRecipe:self.recipeId ofRestaraunt:@"0"];
    
    self.recipeNameLabel.text = [self.recipeName uppercaseString];
    self.recipePriceLabel.text = self.recipePrice;

    self.ingredientsText.text = [self.recipeDetails objectForKey:@"ingredienti"];
    [self.ingredientsText setFont:[UIFont systemFontOfSize:16]];

    self.descriptionText.text = [self.recipeDetails objectForKey:@"descrizione"];
    [self.descriptionText setFont:[UIFont systemFontOfSize:16]];

    [self.recipeImageView sd_setImageWithURL:[[NSURL alloc]initWithString:[BMIMAGEAPI stringByAppendingString:self.recipeImageUrl]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - bar actions

/* Condividi il piatto sui social networks */
- (IBAction)share:(id)sender
{
    NSString *shareString = [NSString stringWithFormat:@"Sto mangiando %@", self.recipeName];
    NSArray *shareContent = @[self.recipeImageView.image, shareString];
    
    NSArray *excludedActivities = @[UIActivityTypeAddToReadingList,
                                    UIActivityTypeAirDrop,
                                    UIActivityTypeAssignToContact,
                                    UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeMail,
                                    UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo,
                                    UIActivityTypePrint,
                                    UIActivityTypeSaveToCameraRoll];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]initWithActivityItems:shareContent applicationActivities:nil];
    
    activityViewController.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

/* Carica i commenti */
- (IBAction)viewComments:(id)sender {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

/* Vota il piatto corrente */
- (IBAction)rateRecipe:(id)sender {
    BMCartManager *cartManager = [BMCartManager sharedInstance];
    
    [cartManager addItemInCart:self.recipeId];
    NSLog(@"ID recipe: %@", self.recipeId);

    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Success" message:@"Aggiunto con successo" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [alert show];
}

/* Accostamenti fattibili */
- (IBAction)loadCombinations:(id)sender {
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier]isEqualToString:@"commentSegue"]) {

        CommentsModalViewController *cmv = [segue destinationViewController];
        cmv.idRecipe = self.recipeId;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

-(void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
