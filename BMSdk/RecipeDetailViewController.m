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
#import "BMUsageStatisticManager.h"
#import "CommentsModalViewController.h"

#import "bestMatchCollectionViewCell.h"

#import "UIImageView+WebCache.h"
#define BMIMAGEAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"

//TEST
#import "BMDownloadManager.h"
#import "AXRatingView.h"
#import "BMCartManager.h"

#import "CRMotionView.h"
#import "TransitionManager.h"

@interface RecipeDetailViewController () <UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
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

@property (strong, nonatomic) BMUsageStatisticManager *statsManager;
@property (strong, nonatomic) IBOutlet UIView *backviewContainer;

@property (strong, nonatomic) NSArray *bestMatchDataSource;
@property (strong, nonatomic) IBOutlet UICollectionView *bestMatchCollectionView;
@property (nonatomic) BOOL isCombinationOpen;
@property (nonatomic) CGPoint originalCenter;

@property (nonatomic) CGPoint firstContainerViewCenter;

@property (strong, nonatomic) IBOutlet UIView *bestMatchSelectedView;
@property (strong, nonatomic) IBOutlet UIImageView *bestMatchRecipeViewBig;
@property (strong, nonatomic) IBOutlet UILabel *bestMatchRecipeViewLabelName;
@property (strong, nonatomic) IBOutlet UILabel *bestMatchRecipeViewLabelIngredients;

@property (strong, nonatomic) CRMotionView *motionView;

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
    return UIStatusBarStyleDefault;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isCombinationOpen = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    
    [self saveViewsCenters];
    
    [self loadDataForCollectionView];
    
    [self addGestureRecognizerToScrollview];
    
    //Setup Center for abbinamenti
    [self setCenterForBestMatchCollection];
    
    self.bestMatchCollectionView.alpha = 0.f;
    self.transitionManager = [[TransitionManager alloc]init];
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    
    
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
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)setCenterForBestMatchCollection
{
    _originalCenter = CGPointMake(self.bestMatchCollectionView.center.x, self.bestMatchCollectionView.center.y);
}


-(void)loadRating
{
    AXRatingView *thisratingView = [[AXRatingView alloc]initWithFrame:CGRectMake(13, 2, 70, 25)];
//    CGPoint center = CGPointMake(55, 17);
    thisratingView.center = self.rateViewContainer.center;
    thisratingView.value = 4.f;
    thisratingView.value =
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

    _motionView = [[CRMotionView alloc]initWithFrame:self.view.frame];
    
    [self.recipeImageView sd_setImageWithURL:[[NSURL alloc]initWithString:[BMIMAGEAPI stringByAppendingString:self.recipeImageUrl]]
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                       if (error) {
                                           NSLog(@"Error download image: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                                       }else
                                       {
                                           NSLog(@"Download completed");
                                           [_motionView setImage:image];
                                           [self.view insertSubview:_motionView atIndex:0];
                                           [_motionView setMotionEnabled:NO];
                                       }
                                   }];
    
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

/** 
 Carica i commenti per la ricetta corrente e inizializza la transizione
 */
- (IBAction)viewComments:(id)sender {

    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    CommentsModalViewController *modal = [self.storyboard instantiateViewControllerWithIdentifier:@"commentsModalView"];
    
    modal.idRecipe = self.recipeId;
    
    [self presentViewController:modal animated:YES completion:nil];
}

/**
 Aggiunge il piatto nella lista da ordinare
 */
- (IBAction)rateRecipe:(id)sender {
    BMCartManager *cartManager = [BMCartManager sharedInstance];
    [cartManager addItemInCart:self.recipeId];
}

/** 
 Accostamenti possibili
 */
- (IBAction)loadCombinations:(id)sender {
    [sender setEnabled:NO];
    if (_isCombinationOpen) {
        //Hide collectionView
        [UIView animateWithDuration:0.3
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:6
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.bestMatchCollectionView.alpha = 0.f;
                             self.bestMatchCollectionView.center = CGPointMake(_originalCenter.x, _originalCenter.y + self.bestMatchCollectionView.frame.size.height);
                             self.bestMatchSelectedView.alpha = 0.f;
                         }
                         completion:^(BOOL finished) {
                             _isCombinationOpen = NO;
                             [sender setEnabled:YES];
                         }];
    }
    else
    {
        //Alter the center of bestMatchCollectionView
        self.bestMatchCollectionView.center = CGPointMake(_originalCenter.x, _originalCenter.y + self.bestMatchCollectionView.frame.size.height);
        
        //Animate it to new position with animation
        [UIView animateWithDuration:0.3
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:6
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.bestMatchCollectionView.alpha = 1.f;
                             self.bestMatchCollectionView.center = _originalCenter;
                         } completion:^(BOOL finished) {
                             _isCombinationOpen = YES;
                             NSLog(@"Completed bestmatch animation");
                             [sender setEnabled:YES];
                         }];
    }
    
}

#pragma mark - Transition to Comments view
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

#pragma mark - BEST MATCH COLLECTION VIEW
-(void)loadDataForCollectionView
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    self.bestMatchDataSource = [NSArray arrayWithArray: [dataManager bestMatchForRecipe:self.recipeId]];
    [self.bestMatchCollectionView reloadData];
}

#pragma mark -
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"%lu", (unsigned long)[self.bestMatchDataSource count]);
    return [self.bestMatchDataSource count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"bestMatchIdentifier";
    
    bestMatchCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSLog(@"BestMatch datasource %@", [self.bestMatchDataSource description]);
    
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[BMIMAGEAPI stringByAppendingString:[[self.bestMatchDataSource objectAtIndex:indexPath.row] objectForKey:@"immagine"]]]];
    cell.imageView.layer.borderColor = [UIColor blackColor].CGColor;
    cell.imageView.layer.borderWidth = 1.f;
    cell.categoryName.text = [[self.bestMatchDataSource objectAtIndex:indexPath.row] objectForKey:@"categoria"];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGPoint bestMatchContainerCenter = CGPointMake(self.bestMatchSelectedView.center.x, self.bestMatchSelectedView.center.y + self.view.frame.size.height/2);
    
    self.bestMatchSelectedView.center = CGPointMake(bestMatchContainerCenter.x, bestMatchContainerCenter.y);
    
    self.bestMatchSelectedView.layer.cornerRadius = 10.f;
    self.bestMatchSelectedView.layer.borderColor = [UIColor blackColor].CGColor;
    self.bestMatchSelectedView.layer.borderWidth = 1.f;

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.bestMatchSelectedView.center = self.bestMatchSelectedView.center;
                         self.bestMatchSelectedView.alpha = 1.f;
                     }
                     completion:^(BOOL finished) {
                         NSLog(@"Completed transition");
                     }];

    self.bestMatchRecipeViewLabelName.text = [[self.bestMatchDataSource objectAtIndex:indexPath.row] objectForKey:@"nome"];

    self.bestMatchRecipeViewBig.clipsToBounds = YES;
    self.bestMatchRecipeViewBig.layer.cornerRadius = 10.f;
    
    [self.bestMatchRecipeViewBig sd_setImageWithURL:[NSURL URLWithString:[BMIMAGEAPI stringByAppendingString:[[self.bestMatchDataSource objectAtIndex:indexPath.row]objectForKey:@"immagine"]]]];
    
    self.bestMatchRecipeViewLabelIngredients.text = [[self.bestMatchDataSource objectAtIndex:indexPath.row] objectForKey:@"ingredienti"];
    
}

- (IBAction)closeBestMatchSingleView:(id)sender {
    
    [sender setEnabled:NO];
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.bestMatchSelectedView.alpha = 0.f;
                     } completion:^(BOOL finished) {
                         self.bestMatchRecipeViewBig.image = nil;
                         [sender setEnabled:YES];
                     }];
}

/**
 Saves the topViewCenter
 */
-(void)saveViewsCenters
{
    self.firstContainerViewCenter = self.backviewContainer.center;

}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

-(void)addGestureRecognizerToScrollview
{
    UIPanGestureRecognizer *pangesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureInsideScrollview:)];
    pangesture.delegate = self;
    [self.scrollView addGestureRecognizer:pangesture];
}

-(void)panGestureInsideScrollview:(UIPanGestureRecognizer *)gestureRecognizer
{

    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {

        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat panDifference = 0;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            panDifference = screenSize.height > 480.f ? 15 : 5;
        }

        if (self.scrollView.contentOffset.y < 0 & self.scrollView.contentOffset.y <= -panDifference) {

            //Determine the alpha value to applicate after a scroll of 15px
            float alphaTransitionValue = 1+((self.scrollView.contentOffset.y + panDifference) * 2)/100;

            [self.motionView setMotionEnabled:YES];
            self.backviewContainer.alpha = alphaTransitionValue;
            self.scrollView.alpha = alphaTransitionValue;
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.2 animations:^{
            [self.motionView setMotionEnabled:NO];
            self.backviewContainer.alpha = 1;
            self.scrollView.alpha = 1;
        }];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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

@end
