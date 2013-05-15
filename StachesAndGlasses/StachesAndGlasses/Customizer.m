//
//  Customizer.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/15/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This is a simple utility class that provides customization methods for UIButtons and UIViews.  I tried using
//  appearance proxies in the AppDelegate to accomplish this, but doing so affected other parts of the app that
//  I did not want to change, such as the UIImagePickerController.  I tried using the method
//  'appearanceWhenContainedIn:' to customzie the UIButtons, but could not get it to work.  Creating a utility
//  class therefore seemed like a relatively simple solution.

#import "Customizer.h"

@implementation Customizer

+ (void)customizeButton:(UIButton *)button
{
    UIImage *blackButton = [[UIImage imageNamed:@"blackButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *blackButtonHighlight = [[UIImage imageNamed:@"blackButtonHighlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    
    [button setBackgroundImage:blackButton forState:UIControlStateNormal];
    [button setBackgroundImage:blackButtonHighlight forState:UIControlStateHighlighted];
}

+ (void)customizeView:(UIView *)view
{
    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"grid_noise"]];
}


@end
