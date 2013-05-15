//
//  PhotoScreenViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/12/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This class allows the user to select an image to use either from their camera or from their photo library.
//  A UIImagePickerController is used to access the camera and library.  Once a user selects an image, the
//  'use this image' button becomes enabled and they can move on to the next view controller.


#import "PhotoScreenViewController.h"
#import "EditPhotoViewController.h"
#import "Customizer.h"
#import <QuartzCore/QuartzCore.h>

@interface PhotoScreenViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UIImagePickerController *picker;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *useThisImageButton;
@property (weak, nonatomic) IBOutlet UIButton *fromCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *fromLibraryButton;

@end


@implementation PhotoScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Customizer customizeView:self.view];
    
    [Customizer customizeButton:self.useThisImageButton];
    [Customizer customizeButton:self.fromCameraButton];
    [Customizer customizeButton:self.fromLibraryButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if a camera is not available on the user's device, the camera button is disabled
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.fromCameraButton.enabled = NO;
        self.fromCameraButton.alpha = 0.5;
    }

    // the 'use this image' button is disabled unless the user has selected an image
    if (!self.imageView.image) {
        self.useThisImageButton.enabled = NO;
        self.useThisImageButton.alpha = 0.5;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // passes the selected image to the next view controller
    if ([[segue identifier] isEqualToString:@"PushToEditPicture"]) {
        EditPhotoViewController *epvc = [segue destinationViewController];
        epvc.selectedImage = self.imageView.image;
    }
}

// lazy instantiation for the UIImagePickerController
- (UIImagePickerController *)picker
{
    if (!_picker) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.allowsEditing = YES;
        _picker.delegate = self;
    }
    return _picker;
}


#pragma mark - Image picker controller delegate

// dismisses the image picker controller when the user taps the cancel button
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"User tapped cancel button");
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// when the user selects an image in the image picker controller, sets that image to this view controller's imageView
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"User selected an image");
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *photo = info[@"UIImagePickerControllerEditedImage"];
    self.imageView.image = photo;
    
    // enables the 'use this image' button once an image has been selected
    self.useThisImageButton.enabled = YES;
    self.useThisImageButton.alpha = 1.0;
}


#pragma mark - Button methods

// displays an image picker controller that allows the user to take a picture using the camera
- (IBAction)fromCameraButtonTapped
{
    NSLog(@"'From this camera' button tapped");
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.picker animated:YES completion:nil];
}

// displays an image picker controller that allows the user to select an image from their photo library
- (IBAction)fromLibraryButtonTapped
{
    NSLog(@"'From library' button tapped");
    self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (IBAction)useThisPhotoButtonTapped
{
    NSLog(@"'Use this photo' button tapped");
}


@end
