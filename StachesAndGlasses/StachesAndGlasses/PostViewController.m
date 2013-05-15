//
//  PostViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/13/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This is a view controller that allows the user to save the finished image to their Photos app or to post
//  it to the web (stachesandglasses.appspot.com), facebook, or twitter.  These functions are only available
//  if the user has an internet connection.  Posting to facebook or twitter requires having an account pre-
//  configured in the device's Settings menu.  Posting an image to the web will add it to the web page
//  http://stachesandglasses.appspot.com/user/rtimpone/web/.  Note that there is no way to delete an image
//  once it is posted to the site.  As this is the last view controller in the image creation process,
//  a 'done' button at the top right of the screen will return the user back to the home screen.  


#import "PostViewController.h"
#import "NetworkingHelper.h"
#import "MBProgressHUD.h"
#import "Customizer.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Social/Social.h>

@interface PostViewController () <NetworkingHelperDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *saveToPhotosButton;
@property (weak, nonatomic) IBOutlet UIButton *shareOnTheWebButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;

@end


@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Customizer customizeView:self.view];    
    
    [Customizer customizeButton:self.saveToPhotosButton];
    [Customizer customizeButton:self.shareOnTheWebButton];
    [Customizer customizeButton:self.facebookButton];
    [Customizer customizeButton:self.twitterButton];
    
    self.imageView.image = self.finishedImage;

    [[NetworkingHelper sharedNetworkingHelper] setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if no internet connection is detected, the buttons to share on the web and post to facebook/twitter are disabled
    if ([[NetworkingHelper sharedNetworkingHelper] noInternetConnection]) {
        
        self.facebookButton.enabled = NO;
        self.facebookButton.alpha = 0.5;
        
        self.twitterButton.enabled = NO;
        self.twitterButton.alpha = 0.5;
        
        self.shareOnTheWebButton.enabled = NO;
        self.shareOnTheWebButton.alpha = 0.5;
    }
}

// Saves the image to the user's photo library and keeps track of its filepath in NSUserDefaults
// Used stackoverflow.com/questions/4457904 for help with saving an image using ALAssetsLibrary
- (IBAction)saveToPhotosButtonTapped
{
    NSLog(@"Save to photos button tapped");
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Saving image...";
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:[self.finishedImage CGImage]
                              orientation:(ALAssetOrientation)[self.finishedImage imageOrientation]
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              
                              // adds the image's data to NSUserDefaults
                              [self addImageDataToUserDefaults:assetURL];
                              
                              [MBProgressHUD hideHUDForView:self.view animated:YES];
                              [self showImageSavedAlertView];
                          }];
}

// Lets the user know that the image was saved to their Photos app
- (void)showImageSavedAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Saved"
                                                    message:@"The image has been saved to your Photos"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

// Saves the date that the image was created and the image's filpath to NSUserDefaults.  This currently does not serve
// any major funtionality in the app, it was implemented to fulfill one of the assignment's requirements: "... and
// maintain a list of photos that you have created."  This method fulfills that requirement by saving the date that the
// image was created and its filepath, which is enough to sort the images in chronological order and to access them using
// the filepath if needed in the future.  
- (void)addImageDataToUserDefaults:(NSURL *)imageURL
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *savedImages = [[defaults objectForKey:@"saved_images"] mutableCopy];
    
    if (!savedImages) {
        savedImages = [@[] mutableCopy];
    }
    
    // creates a dictionary that holds the image date and image file path
    NSMutableDictionary *imageData = [@{} mutableCopy];
    [imageData setValue:[imageURL absoluteString] forKey:@"image_url"];
    [imageData setValue:[NSDate date] forKey:@"date"];
    
    [savedImages addObject:imageData];
    
    [defaults setValue:savedImages forKey:@"saved_images"];
    [defaults synchronize];
}

// Posts the image to http://stachesandglasses.appspot.com/user/rtimpone/web/ using the NetworkingHelper utility class
- (IBAction)shareOnWebButtonTapped
{
    NSLog(@"Share on web button tapped");
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Posting to website...";
    
    [[NetworkingHelper sharedNetworkingHelper] postImageToAppSpot:self.finishedImage];
}

// The delegate method that gets called when NetworkingHelper finishes posting the image to appspot
- (void)helperFinishedPostingImage
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Posted"
                                                    message:@"The image has been posted to http://stachesandglasses.appspot.com/user/rtimpone/web/"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

// Displays an SLComposeViewController that allows the user to post the image to facebook (must have a facebook account configured in Settings)
- (IBAction)postToFacebookButtonTapped
{
    NSLog(@"Post to facebook button tapped");
    
    SLComposeViewController *facebookController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [facebookController setInitialText:@"Check out this image I made on Staches and Glasses!"];
    [facebookController addImage:self.finishedImage];
    [self presentViewController:facebookController animated:YES completion:nil];
}

// Displays an SLComposeViewController that allows the user to post the image to twitter (must have a twitter account configured in Settings)
- (IBAction)postToTwitterButtonTapped
{
    NSLog(@"Post to twitter button tapped");
    
    SLComposeViewController *twitterController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [twitterController setInitialText:@"Check out this image I made on Staches and Glasses!"];
    [twitterController addImage:self.finishedImage];
    [self presentViewController:twitterController animated:YES completion:nil];
}

// Transitions the use back through the navigation controller to the home screen
// Used post at stackoverflow.com/questions/5752297 for help with this
- (IBAction)doneButtonTapped:(id)sender
{
    NSLog(@"Done button tapped");
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:0] animated:YES];
}


@end
