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
#import "AXRatingView.h"
#import "BMCartManager.h"

#import "TransitionManager.h"

@interface RecipeDetailViewController () <UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;

@property (strong, nonatomic) IBOutlet UILabel *recipeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipePriceLabel;

@property (strong, nonatomic) IBOutlet UILabel *recipeIngredientsLabel;
@property (strong, nonatomic) IBOutlet UILabel *recipeDescriptionLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIView *rateViewContainer;
@property (strong, nonatomic) IBOutlet UIView *secondaryInfoView;

@property (strong, nonatomic) IBOutlet UILabel *descriptionTextLabel;
@property (strong, nonatomic) IBOutlet UILabel *ingredientsTextLabel;


@property (strong, nonatomic) NSMutableDictionary *recipeDetails;
@property (nonatomic, strong) TransitionManager *transitionManager;

@end

@implementation RecipeDetailViewController

-(void)viewDidLayoutSubviews
{
    CGFloat heightSize = 0;

    for (UILabel *label in self.secondaryInfoView.subviews) {
        heightSize += label.frame.size.height + 8;
    }
    
    heightSize += 69;
    
    self.scrollView.contentSize = CGSizeMake(320, heightSize);
}

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
    self.transitionManager = [[TransitionManager alloc]init];
    
    //return to previous view
    UIScreenEdgePanGestureRecognizer *sepg = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(pop)];
    sepg.delegate = self;
    [sepg setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:sepg];
    
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    
    //Text bigger
    self.recipeNameLabel.text = [self.recipeNameLabel.text uppercaseString];
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    [self.rateViewContainer setBackgroundColor:[UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1]];
    
    [self loadRecipeData];
    [self loadRating];
    

    
    BMDownloadManager *dm = [BMDownloadManager sharedInstance];
    BMDataManager *dataManage = [BMDataManager sharedInstance];
    
    if ([dataManage shouldFetchCommentsFromServer:self.recipeId]) {
        NSLog(@"[RecipeDetailViewController] Comments not found for recipeID %@, name: %@", self.recipeId, self.recipeName);
        [dm fetchCommentsForRecipe:self.recipeId];
    }
    else
    {
        NSLog(@"[RecipeDetailViewController] Comments found in database");
    }
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

-(void)loadRating
{
    AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, 25)];
    CGPoint center = CGPointMake(55, 17);
    thisratingView.center = center;
    thisratingView.value = 4.f;
    thisratingView.tag = 114;
    thisratingView.numberOfStar = 5;
    thisratingView.baseColor = [UIColor blackColor];
    thisratingView.highlightColor = [UIColor whiteColor];
    
    thisratingView.userInteractionEnabled = NO;
    thisratingView.stepInterval = 1.f;
    
    [self.rateViewContainer addSubview:thisratingView];
}

-(void)loadRecipeData
{
    
    UIFont *fontForItems = [UIFont systemFontOfSize:16];
    
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    [[NSUserDefaults standardUserDefaults]objectForKey:@"//RESTARAUNT"];

    self.recipeDetails = [dataManager requestDetailsForRecipe:self.recipeId ofRestaraunt:@"0"];
    
    self.recipeNameLabel.text = [self.recipeName uppercaseString];
    self.recipePriceLabel.text = self.recipePrice;

    self.ingredientsTextLabel.text = [self.recipeDetails objectForKey:@"ingredienti"];
    [self.ingredientsTextLabel setFont:fontForItems];

    self.descriptionTextLabel.text = [self.recipeDetails objectForKey:@"descrizione"];
    [self.descriptionTextLabel setFont:fontForItems];
    
    self.recipeImageView.clipsToBounds = YES;
    [self.recipeImageView sd_setImageWithURL:[[NSURL alloc]initWithString:[BMIMAGEAPI stringByAppendingString:self.recipeImageUrl]]];
    
    [self.secondaryInfoView sizeToFit];
    self.contentViewHeight.constant = self.secondaryInfoView.frame.size.height;
    
}

-(void)setConstraint
{
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.secondaryInfoView attribute:NSLayoutAttributeLeading relatedBy:0 toItem:self.scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.secondaryInfoView attribute:NSLayoutAttributeTrailing relatedBy:0 toItem:self.scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    
    [self.view addConstraint:rightConstraint];
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

    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    UIStoryboard *BMStoryboard = [UIStoryboard storyboardWithName:@"BMStoryboard"
                                                                                                    bundle:[NSBundle bundleWithIdentifier:@"com.blueMate.BMSdk"]];
    
    CommentsModalViewController *modal = [BMStoryboard instantiateViewControllerWithIdentifier:@"commentsModalView"];
    
    modal.idRecipe = self.recipeId;
    
    modal.transitioningDelegate = self;
    modal.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:modal animated:YES completion:nil];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.transitionManager.transitionTo = MODAL;
    return self.transitionManager;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.transitionManager.transitionTo = INITIAL;
    return self.transitionManager;
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
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
