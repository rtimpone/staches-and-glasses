//
//  DrawingViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/12/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This view controller handles onscreen drawing that the user adds to the image by drawing with their finger.
//  The controller works with a PaintView that is located directly on top of the imageView to get paths that
//  are drawn and merge them with the current image.  This is an optimization becuase paths do not need to be
//  redrawn every time a new stroke is added - only one path is drawn at any time.  A second optimization takes
//  place in the merging because only the 'dirty' part of the PaintView (the part of the rect that was actually
//  drawn on) is merged with the main image.  This results in higher performance drawing than would be available
//  using simpler techniques.  The user can select the colors of the lines that they draw from a selection of
//  onscreen 'paint splat' buttons.  


#import "DrawingViewController.h"
#import "PaintView.h"
#import "Customizer.h"
#import <QuartzCore/QuartzCore.h>
#import "StacheGlassesViewController.h"

@interface DrawingViewController () <PaintViewDelegate>

@property (weak, nonatomic) IBOutlet PaintView *paintView;      // the paint view lies on top of the imageView
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIButton *yellowButton;
@property (weak, nonatomic) IBOutlet UIButton *orangeButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *pinkButton;
@property (weak, nonatomic) IBOutlet UIButton *purpleButton;
@property (weak, nonatomic) IBOutlet UIButton *blueButton;
@property (weak, nonatomic) IBOutlet UIButton *cyanButton;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;

@end


// colors for the drawing in paint view
#define CYAN [UIColor colorWithRed:0/255.0 green:244/255.0 blue:255/255.0 alpha:1.0]
#define BLUE [UIColor colorWithRed:60/255.0 green:0/255.0 blue:255/255.0 alpha:1.0]
#define YELLOW [UIColor colorWithRed:255/255.0 green:250/255.0 blue:0/255.0 alpha:1.0]
#define RED [UIColor colorWithRed:255/255.0 green:13/255.0 blue:0/255.0 alpha:1.0]
#define PURPLE [UIColor colorWithRed:167/255.0 green:0/255.0 blue:255/255.0 alpha:1.0]
#define PINK [UIColor colorWithRed:255/255.0 green:0/255.0 blue:251/255.0 alpha:1.0]
#define ORANGE [UIColor colorWithRed:255/255.0 green:164/255.0 blue:0/255.0 alpha:1.0]
#define GREEN [UIColor colorWithRed:0/255.0 green:255/255.0 blue:3/255.0 alpha:1.0]

@implementation DrawingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Customizer customizeView:self.view];
    
    // sets the default 'paint' color in the PaintView
    self.paintView.lineColor = GREEN;

    self.paintView.delegate = self;
    self.imageView.image = self.filteredImage;
    self.scrollView.contentSize = CGSizeMake(517, 73);
    
    // applies the corresponding 'paint splat' image to each paint color button
    [self.yellowButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_yellow"] forState:UIControlStateNormal];
    [self.orangeButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_orange"] forState:UIControlStateNormal];
    [self.redButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_red"] forState:UIControlStateNormal];
    [self.pinkButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_pink"] forState:UIControlStateNormal];
    [self.purpleButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_purple"] forState:UIControlStateNormal];
    [self.blueButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_blue"] forState:UIControlStateNormal];
    [self.cyanButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_cyan"] forState:UIControlStateNormal];
    [self.greenButton setBackgroundImage:[UIImage imageNamed:@"paint_splat_green"] forState:UIControlStateNormal];
}

// Passes the painted image to the next view controller
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"test"]) {
        StacheGlassesViewController *sgvc = [segue destinationViewController];
        sgvc.paintedImage = self.imageView.image;
    }
}


#pragma mark - Drawing merge methods

// Receives the area that was painted from the paint view after the user is finished drawing a path
- (void)paintView:(PaintView *)paintView finishedTrackingPathInRect:(CGRect)paintedArea
{
    NSLog(@"Delegate received dirty rect");
    [self mergePaintToBackgroundView:paintedArea];
}

// Combines the user's recently painted path with the image in self.imageView
- (void)mergePaintToBackgroundView:(CGRect)painted
{
    NSLog(@"Merging paint view into background view");
    
    // Creating a new offscreen buffer to merge the images in
    CGRect bounds = self.imageView.bounds;
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, self.imageView.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Copying the image currently in self.imageView into the context
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    [self.imageView.layer renderInContext:context];

    // Copying the recently painted path from the paint view and putting it on top of the image in the context.
    // As an optimization, the clip area is set to we only copy the area of paint view that was actually drawn on.
    CGContextClipToRect(context, painted);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [self.paintView.layer renderInContext:context];

    // Now that the paint view has been merged with the imageView, we can clear the paint view
    [self.paintView clearPaintView];
    
    // Creating an image from the graphics context and setting the current image onscreen to it
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    self.imageView.image = image;
    UIGraphicsEndImageContext();
}


#pragma mark - Paint button methods

// These methods set the PaintView line color based on which paint splat button the user tapped
- (IBAction)yellowButtonTapped {self.paintView.lineColor = YELLOW;}
- (IBAction)orangeButtonTapped {self.paintView.lineColor = ORANGE;}
- (IBAction)redButtonTapped {self.paintView.lineColor = RED;}
- (IBAction)pinkButtonTapped {self.paintView.lineColor = PINK;}
- (IBAction)purpleButtonTapped {self.paintView.lineColor = PURPLE;}
- (IBAction)blueButtonTapped {self.paintView.lineColor = BLUE;}
- (IBAction)cyanButtonTapped {self.paintView.lineColor = CYAN;}
- (IBAction)greenButtonTapped {self.paintView.lineColor = GREEN;}


@end
