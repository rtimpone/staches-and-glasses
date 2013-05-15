//
//  EnlargeImageViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/15/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This is a simple view controller with a large imageView.  It is designed to be shown modally from
//  HomeScreenViewController to show a larger version of an image that is tapped in the collection
//  view.  Whenever a tap is detected, this view controller will dismiss itself.


#import "EnlargeImageViewController.h"

@interface EnlargeImageViewController()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end


@implementation EnlargeImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.image = self.image;
}

// dismisses the view controller whenever a touch is detected
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
