//
//  StacheGlassesViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/13/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This view controller uses Apple facial detection software to attempt to locate facial features which, if found,
//  allow the user to add images of a mustache and/or glasses to each face identified in the image.  The mustache
//  and glasses images are scaled based on the size of the face, and are angled depending on the angle of the face.
//  If the facial detection software fails to locate facial features in the image, these functions will be
//  unavailable to the user.  
//
//  Note that the accuracy of the Apple-provided facial detection software can be significantly affected by filters
//  and drawing added to the image.  Facial detection is much more accurate when a simple filter like sepia is used
//  and onscreen drawing is kept to a minimum.


#import "StacheGlassesViewController.h"
#import "PostViewController.h"
#import "MBProgressHUD.h"
#import "Customizer.h"
#import <QuartzCore/QuartzCore.h>

@interface StacheGlassesViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) BOOL faceDetectionAttempted;      // indicates whether facial detection needs to be run on the image
@property (strong, nonatomic) NSMutableArray *faceDetectionResults;

@property (weak, nonatomic) IBOutlet UIButton *stacheButton;
@property (weak, nonatomic) IBOutlet UIButton *glassesButton;

@end


@implementation StacheGlassesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Customizer customizeView:self.view];    
    
    [Customizer customizeButton:self.stacheButton];
    [Customizer customizeButton:self.glassesButton];
    
    // these buttons are disabled by default - they are only enabled if facial features are detected
    self.stacheButton.enabled = NO;
    self.glassesButton.enabled = NO;
    self.stacheButton.alpha = 0.5;
    self.glassesButton.alpha = 0.5;
    
    // sets the BOOL to no, which will cause facial detection to be attempted when viewWillAppear is called
    self.faceDetectionAttempted = NO;
    
    // scales the image, which helps with facial detection methods
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 320), NO, 0.0);
    [self.paintedImage drawInRect:CGRectMake(0, 0, 320, 320)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.imageView.image = scaledImage;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if facial detection has not already been attempted on this image, runs the facial detection method
    if (!self.faceDetectionAttempted) {
        [self findFaces:self.imageView];
    }
}

// passes the image to the next view controller
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CGRect rect = self.imageView.bounds;
    
    // this 'flattens' the image so the glasses and/or mustache imageViews become part of the main image
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.imageView.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if ([[segue identifier] isEqualToString:@"PushToPostViewControllerSegue"]) {
        PostViewController *pvc = [segue destinationViewController];
        pvc.finishedImage = capturedImage;
    }
}

- (NSMutableArray *)faceDetectionResults
{
    if (!_faceDetectionResults) _faceDetectionResults = [@[] mutableCopy];
    return _faceDetectionResults;
}


#pragma mark - Face detection methods

// Attemps to use CIDetector to locate facial features in the image
-(void)findFaces:(UIImageView *)imageView
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Running facial detection...";
    
    // marks the BOOL as yes to prevent re-running facial detection if the user hits the 'back' button on the next view controller
    self.faceDetectionAttempted = YES;
    
    // this will happen on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // sets up the image and the CIDetector
        CIImage *image = [[CIImage alloc] initWithImage:self.imageView.image];
        NSString *accuracy = CIDetectorAccuracyHigh;
        NSDictionary *options = [NSDictionary dictionaryWithObject:accuracy forKey:CIDetectorAccuracy];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
        
        // gets an array of facial features that the detector found in the image
        NSArray *features = [detector featuresInImage:image];
    
        // this happens back on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self analyzeFeatures:features];
        });
    });
}

// Analyzes the facial features that the CIDetector found in the image
// Used nacho4d-nacho4d.blogspot.com/2012/03/coreimage-and-uikit-coordinates.html for help with this
- (void)analyzeFeatures:(NSArray *)features
{
    // if no features were found, the buttons remain disabled and an alert view is shown to the user
    if ([features count] == 0) {
        [self showCouldNotLocateFeaturesAlert];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }

    // scales the image size to standardize the methods for retina vs. non-retina devices
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat imageSize = 320 * scale;
    
    // variables used for adjusting the calculations below
    float imageX = 0;
    float imageY = (20 + 44) * scale + 10;
    
    // this is done for each feature located in the 'features' array - there may be more than one person in the image
    for (CIFaceFeature *feature in features) {
        
        NSMutableDictionary *result = [@{} mutableCopy];   // stores the results of the facial features detection
        
        // if a left eye was detected, converts its location to the UIKit coordinate system and adds it to the results dictionary
        if (feature.hasLeftEyePosition) {
            NSLog(@"Left eye located: %f, %f",feature.leftEyePosition.x,feature.leftEyePosition.y);
            
            CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
            transform = CGAffineTransformTranslate(transform, 0, -self.imageView.bounds.size.height);
            CGPoint adjustedLeftEye = CGPointApplyAffineTransform(feature.leftEyePosition, transform);
            CGPoint leftEyePosition = CGPointMake(imageX + adjustedLeftEye.x*(200.0/imageSize), imageY + adjustedLeftEye.y*(200.0/imageSize));
            
            [result setValue:[NSValue valueWithCGPoint:leftEyePosition] forKey:@"LEFT_EYE"];
        }
        
        // if a right eye was detected, converts its location to the UIKit coordinate system and adds it to the results dictionary
        if (feature.hasRightEyePosition) {
            NSLog(@"Right eye located: %f, %f",feature.rightEyePosition.x,feature.rightEyePosition.y);
            
            CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
            transform = CGAffineTransformTranslate(transform, 0, -self.imageView.bounds.size.height);
            CGPoint adjustedRightEye = CGPointApplyAffineTransform(feature.rightEyePosition, transform);
            CGPoint rightEyePosition = CGPointMake(imageX + adjustedRightEye.x*(200.0/imageSize), imageY + adjustedRightEye.y*(200.0/imageSize));
            
            [result setValue:[NSValue valueWithCGPoint:rightEyePosition] forKey:@"RIGHT_EYE"];
        }
        
        // if a mouth was detected, converts its location to the UIKit coordinate system and adds it to the results dictionary        
        if (feature.hasMouthPosition) {
            NSLog(@"Mouth located: %f, %f",feature.mouthPosition.x,feature.mouthPosition.y);
            
            CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
            transform = CGAffineTransformTranslate(transform, 0, -self.imageView.bounds.size.height);
            CGPoint adjustedMouth = CGPointApplyAffineTransform(feature.mouthPosition, transform);
            CGPoint mouthPosition = CGPointMake(imageX + adjustedMouth.x*(200.0/imageSize), imageY + adjustedMouth.y*(200.0/imageSize));
            
            [result setValue:[NSValue valueWithCGPoint:mouthPosition] forKey:@"MOUTH"];
        }
        
        // adds each resulting feature to self.faceDetectionResults - again, there may be more than one person in the image
        [self.faceDetectionResults addObject:result];
    }
    
    // enables the stache and glasses button
    self.stacheButton.enabled = YES;
    self.glassesButton.enabled = YES;
    self.stacheButton.alpha = 1.0;
    self.glassesButton.alpha = 1.0;
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];    
}

#define DEGREES_TO_RADIANS(d) (d * M_PI / 180)

// Calculates the angle between two points in degrees
// Found this formula at stackoverflow.com/questions/7586063/
- (CGFloat)angleBetween:(CGPoint)point1 and:(CGPoint)point2
{
    CGFloat dY = point2.y - point1.y;
    CGFloat dX = point2.x - point1.x;
    return DEGREES_TO_RADIANS(atan2f(dY, dX) * 180/M_PI);
}

// Caclulates the distance between two points
- (CGFloat)distanceFrom:(CGPoint)point1 to:(CGPoint)point2
{
    CGFloat x1 = point1.x;
    CGFloat x2 = point2.x;
    
    CGFloat y1 = point1.y;
    CGFloat y2 = point2.y;
    
    return sqrt(pow(x1 - x2, 2.0) + pow(y1 - y2, 2.0));
}

// Calculates the midpoint between two points
- (CGPoint)midPointBetween:(CGPoint)point1 and:(CGPoint)point2
{
    CGFloat x1 = point1.x;
    CGFloat x2 = point2.x;
    
    CGFloat y1 = point1.y;
    CGFloat y2 = point2.y;
    
    return CGPointMake((x1 - x2)/2.0 + x2, (y1 - y2)/2.0 + y2);
}

// Shows an alert to the user letting them know that facial features could not be located in the image
- (void)showCouldNotLocateFeaturesAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Locate Features"
                                                    message:@"Sorry, we were unable to use facial detection to locate the facial features in this image."
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark - Button methods



// Adds an image of a mustache to the main image - the mustache image is scaled and angled based on the size and angle of the face
- (IBAction)addStacheButtonTapped
{
    NSLog(@"Add stache button tapped");
    
    for (NSDictionary *results in self.faceDetectionResults) {
        
        CGPoint leftEye = [results[@"LEFT_EYE"] CGPointValue];
        CGPoint rightEye = [results[@"RIGHT_EYE"] CGPointValue];
        CGPoint mouth = [results[@"MOUTH"] CGPointValue];
        
        CGFloat distanceBetweenEyes = [self distanceFrom:leftEye to:rightEye];
        CGPoint centerOfEyes =  [self midPointBetween:leftEye and:rightEye];
        
        // determines where to put the mustache image based on the distance between the mouth and the midpoint between the eyes
        CGFloat distanceFromMouthToCenterOfEyes = [self distanceFrom:centerOfEyes to:mouth];
        CGPoint mustacheTarget = CGPointMake(mouth.x, mouth.y - (distanceFromMouthToCenterOfEyes * 0.15));
        
        // determines how large to make the mustache image based on the distance between the face's eyes
        CGRect frame = CGRectMake(mustacheTarget.x, mustacheTarget.y, distanceBetweenEyes * 1.5, distanceBetweenEyes * 1.5 * 0.45);
        
        UIImageView *mustache = [[UIImageView alloc] initWithFrame:frame];
        mustache.contentMode = UIViewContentModeScaleAspectFit;
        mustache.image = [UIImage imageNamed:@"mustache"];
        mustache.center = mustacheTarget;
        
        // rotates the mustache image based on the angle of the face (which is determined by the angle from left eye to right eye)
        CGFloat angleBetweenEyes = [self angleBetween:leftEye and:rightEye];        
        mustache.transform = CGAffineTransformMakeRotation(angleBetweenEyes);
        
        [self.imageView addSubview:mustache];
    }
}

// Adds an image of glasses to the main image - the glasses image is scaled and angled based on the size and angle of the face
- (IBAction)addGlassesButtonTapped
{
    NSLog(@"Add glasses button tapped");
    
    for (NSDictionary *results in self.faceDetectionResults) {
        
        CGPoint leftEye = [results[@"LEFT_EYE"] CGPointValue];
        CGPoint rightEye = [results[@"RIGHT_EYE"] CGPointValue];
        
        CGFloat distanceBetweenEyes = [self distanceFrom:leftEye to:rightEye];
        CGPoint centerOfEyes =  [self midPointBetween:leftEye and:rightEye];

        // determines how large to make the glasses image based on the distance between the face's eyes        
        CGRect frame = CGRectMake(centerOfEyes.x, centerOfEyes.y, distanceBetweenEyes * 2.25, distanceBetweenEyes * 2.25 * 0.55);
        
        UIImageView *glasses = [[UIImageView alloc] initWithFrame:frame];
        glasses.contentMode = UIViewContentModeScaleAspectFit;
        glasses.image = [UIImage imageNamed:@"hipster_glasses"];
        
        // positions the glasses image between the face's eyes
        glasses.center = centerOfEyes;
        
        // rotates the glasses image based on the angle of the face (which is determined by the angle from left eye to right eye)        
        CGFloat angleBetweenEyes = [self angleBetween:leftEye and:rightEye];
        glasses.transform = CGAffineTransformMakeRotation(angleBetweenEyes);
        
        [self.imageView addSubview:glasses];
    }
}


@end
