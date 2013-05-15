//
//  HomeScreenViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/12/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This is the view controller for the user's home screen.  It's main function is to download images from appspot.com and
//  display them in a collection view.  When a user taps on an image in the collection view, this class displays an
//  EnlargeImageViewController modally, which features a larger version of the image.  This class controls when images
//  are downloaded by maintaining a BOOL variable imagesNeedRefreshing.  When this is set to YES, the class will refresh
//  the images in its collection view when viewWillAppear is called.  The class also detects whether the user has an
//  internet connection or not, and if they don't, displays an alert view that explains that some functionality may
//  not be availble to them.  Images in the collection view are displayed in chronological order because of that is
//  the way they are downloaded from stachesandglasses.appspot.com by default.  


#import "HomeScreenViewController.h"
#import "ImageCell.h"
#import "MBProgressHUD.h"
#import "NetworkingHelper.h"
#import "Customizer.h"
#import "EnlargeImageViewController.h"

@interface HomeScreenViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NetworkingHelperDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIImageView *footerImageView;
@property (weak, nonatomic) IBOutlet UIButton *createAnImageButton;

@property (strong, nonatomic) NSArray *images;      // images that are displayed onscreen
@property (nonatomic) BOOL imagesNeedRefreshing;    // controls when images are downloaded in viewWillAppear

@end


@implementation HomeScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imagesNeedRefreshing = YES;
    [Customizer customizeButton:self.createAnImageButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    // if there is no internet connection, an alert view is shown
    if ([[NetworkingHelper sharedNetworkingHelper] noInternetConnection]) {
        [self showNoInternetConnectionAlertView];
    }
    
    // if there is an internet connection, images are downloaded from appspot
    else if (self.imagesNeedRefreshing) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading images...";
        
        [[NetworkingHelper sharedNetworkingHelper] setDelegate:self];
        [[NetworkingHelper sharedNetworkingHelper] latestUploads];      // downloads images from stachesandglasses.appspot.com
    }
}

// the delegate method that is called when NetworkingHelper finishes fetching results from appspot
- (void)helperFinishedFetchingResults:(NSArray *)results
{
    NSLog(@"Images received at delegate");
    
    self.images = results;
    [self.collectionView reloadData];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // prevents the images from being re-loaded until the user taps the 'create an image' button
    self.imagesNeedRefreshing = NO;
}

// an alert that explains to the user that some functionality will not be available without an internet connection
- (void)showNoInternetConnectionAlertView
{
    NSString *message = @"An internet connection is required to view and post images. Without an internet connection, you will not be able to view previous images and you will not be able to post images to the web, facebook, or twitter";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark - UICollectionView data source methods

// The number of cells that will be displayed
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ImageCell";
    ImageCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    // each cell has a 'top image' (the polaroid .png with the middle section transparent) and a 'bottom image' (the image showing through the middle)
    cell.bottomImageView.image = self.images[indexPath.row];
    
    return cell;
}


#pragma mark - UICollectionViewFlowLayout delegate methods

// Displays a modal view controller with a larger version of the image when a user taps on a cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"User tapped cell at index %d",indexPath.row);
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    EnlargeImageViewController *eivc = [storyboard instantiateViewControllerWithIdentifier:@"EnlargeImageViewController"];
    eivc.image = self.images[indexPath.row];
    
    [self presentViewController:eivc animated:YES completion:nil];
}

// Controls the spacing between the cells and the header, footer, and sides
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(15, 15, 15, 15);
}

// Controls the spacing between each row of cells
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20;
}


#pragma mark - Button methods

- (IBAction)createImageButtonTapped
{
    NSLog(@"Create an image button tapped");
    
    // resets this boolean so next time the user reaches the home page, images are reloaded (usually when the user taps 'done' after creating a new image)
    self.imagesNeedRefreshing = YES;
}


@end
