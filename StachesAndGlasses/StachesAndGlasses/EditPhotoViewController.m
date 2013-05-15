//
//  EditPhotoViewController.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/12/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This class allows the user to select a filter to apply to the main image.  The filter buttons at the bottom of
//  the screen display a preview of what the image will look like once the filter is applied.  When the user taps
//  on a filter button, that filter is applied to the main image.  When the user taps 'next', the filtered image
//  is passed on to the next view controller.  Creating the thumbnail image takes a few seconds, so a progress
//  indicator is displayed onscreen while they are being generated.  


#import "EditPhotoViewController.h"
#import "DrawingViewController.h"
#import "Customizer.h"
#import "MBProgressHUD.h"

@interface EditPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) CIImage *originalImage;
@property (strong, nonatomic) CIImage *thumbnailImage;

@property (strong, nonatomic) NSMutableDictionary *thumbnails;

@property (weak, nonatomic) IBOutlet UIButton *originalButton;
@property (weak, nonatomic) IBOutlet UIButton *sepiaButton;
@property (weak, nonatomic) IBOutlet UIButton *monochromeButton;
@property (weak, nonatomic) IBOutlet UIButton *bloomButton;
@property (weak, nonatomic) IBOutlet UIButton *hueAdjustButton;
@property (weak, nonatomic) IBOutlet UIButton *invertButton;
@property (weak, nonatomic) IBOutlet UIButton *posterizeButton;
@property (weak, nonatomic) IBOutlet UIButton *dotScreenButton;
@property (weak, nonatomic) IBOutlet UIButton *gloomButton;
@property (weak, nonatomic) IBOutlet UIButton *pixellateButton;
@property (weak, nonatomic) IBOutlet UIButton *brightnessButton;

@end


@implementation EditPhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Customizer customizeView:self.view];
    
    self.scrollView.contentSize = CGSizeMake(1000, 100);
    self.imageView.image = self.selectedImage;
    
    // creates a CIImage version of the selected image - this is the image that the filters will operate on
    self.originalImage = [[CIImage alloc] initWithImage:self.selectedImage];
    
    // creates a scaled-down version of the image for the thumbnails
    self.thumbnailImage = [UIImage imageWithCIImage:self.originalImage scale:0.3 orientation:UIImageOrientationUp].CIImage;
    
    [self setupThumbnails];
}

// passes the filtered image to the next view controller
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"PushToDrawOnImage"]) {
        DrawingViewController *dvc = [segue destinationViewController];
        dvc.filteredImage = self.imageView.image;
    }
}

- (CIContext *)context
{
    if (!_context) _context = [CIContext contextWithOptions:nil];
    return _context;
}

- (NSMutableDictionary *)thumbnails
{
    if (!_thumbnails) _thumbnails = [@{} mutableCopy];
    return _thumbnails;
}


#pragma mark - Thumbnail methods

// Creates a filtered 'preview' thumbnail for each of the filter buttons
- (void)setupThumbnails
{
    NSLog(@"Started creating thumbnails");
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading thumbnails...";
    
    // this is done on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        // generates the thumbnail images
        [self createThumbnailImages];
        
        // this is done back on the main thread once the background thread is done
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            NSLog(@"Finished creating thumbnails");
            
            // assigns each thumbnail image to the appropriate button
            [self setThumbnailImageForButton:self.originalButton];
            [self setThumbnailImageForButton:self.sepiaButton];
            [self setThumbnailImageForButton:self.monochromeButton];
            [self setThumbnailImageForButton:self.bloomButton];
            [self setThumbnailImageForButton:self.hueAdjustButton];
            [self setThumbnailImageForButton:self.invertButton];
            [self setThumbnailImageForButton:self.posterizeButton];
            [self setThumbnailImageForButton:self.dotScreenButton];
            [self setThumbnailImageForButton:self.gloomButton];
            [self setThumbnailImageForButton:self.pixellateButton];
            [self setThumbnailImageForButton:self.brightnessButton];
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
    });
}

// Creates a filtered thumbnail image for each filter that can be selected
- (void)createThumbnailImages
{
    [self.thumbnails setValue:[UIImage imageWithCIImage:self.thumbnailImage] forKey:[self.originalButton description]];
    
    // sepia thumbnail
    CIFilter *sepiaFilter = [self sepiaFilterForImage:self.thumbnailImage];
    [self useFilter:sepiaFilter toSetThumbnailForButton:self.sepiaButton];
    
    // monochrome thumbnail
    CIFilter *monochromeFilter = [self monochromeFilterForImage:self.thumbnailImage];
    [self useFilter:monochromeFilter toSetThumbnailForButton:self.monochromeButton];
    
    // bloom thumbnail
    CIFilter *bloomFilter = [self bloomFilterForImage:self.thumbnailImage];
    [self useFilter:bloomFilter toSetThumbnailForButton:self.bloomButton];
    
    // hue adjust thumbnail
    CIFilter *hueFilter = [self hueFilterForImage:self.thumbnailImage];
    [self useFilter:hueFilter toSetThumbnailForButton:self.hueAdjustButton];
    
    // invert thumbnail
    CIFilter *invertFilter = [self invertFilterForImage:self.thumbnailImage];
    [self useFilter:invertFilter toSetThumbnailForButton:self.invertButton];
    
    // posterize thumbnail
    CIFilter *posterizeFilter = [self posterizeFilterForImage:self.thumbnailImage];
    [self useFilter:posterizeFilter toSetThumbnailForButton:self.posterizeButton];
    
    // dot screen thumbnail
    CIFilter *dotScreenFilter = [self dotScreenFilterForImage:self.thumbnailImage];
    [self useFilter:dotScreenFilter toSetThumbnailForButton:self.dotScreenButton];
    
    // gloom thumbnail
    CIFilter *gloomFilter = [self gloomFilterForImage:self.thumbnailImage];
    [self useFilter:gloomFilter toSetThumbnailForButton:self.gloomButton];
    
    // pixellate thumbnail
    CIFilter *pixellateFilter = [self pixellateFilterForImage:self.thumbnailImage];
    [self useFilter:pixellateFilter toSetThumbnailForButton:self.pixellateButton];
    
    // brightness thumbnail
    CIFilter *brightnessFilter = [self brightnessFilterForImage:self.thumbnailImage];
    [self useFilter:brightnessFilter toSetThumbnailForButton:self.brightnessButton];
}

// Gets a button's corresponding thumbnail from self.thumbnails and sets it as the background image for that button
- (void)setThumbnailImageForButton:(UIButton *)button
{
    UIImage *thumbnail = self.thumbnails[[button description]];
    [button setBackgroundImage:thumbnail forState:UIControlStateNormal];
}

// Applies the specified filter and adds it to the dictionary self.thumbnails with the key [button description]
- (void)useFilter:(CIFilter *)filter toSetThumbnailForButton:(UIButton *)button
{
    UIImage *image = [self applyFilter:filter];
    [self.thumbnails setValue:image forKey:[button description]];
}


#pragma mark - General filter methods

// A convenience method that returns a CIFilter object given a filter name and an image to apply the filter to
- (CIFilter *)getFilter:(NSString *)filterName forImage:(CIImage *)image
{
    CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, image, nil];
    return filter;
}

// A convenience method that returns a CIFilter object given a filter name, desired intensity level, and an image to apply the filter to
- (CIFilter *)getFilter:(NSString *)filterName withIntensity:(NSNumber *)intensity forImage:(CIImage *)image
{
    CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, image, @"inputIntensity", intensity, nil];
    return filter;
}

// Applies a filter and returns the resulting image as a UIImage
- (UIImage *)applyFilter:(CIFilter *)filter
{
    CIImage *outputImage = [filter outputImage];
    CGImageRef imageRef = [self.context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    
    return newImage;
}


#pragma mark - Individual filter methods

// Each of the following methods returns a CIFilter object given an image (these are used in the button action methods):

- (CIFilter *)monochromeFilterForImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputImageKey,self.thumbnailImage,
                                                                       @"inputColor", [CIColor colorWithRed:0.3 green:0.3 blue:0.3],
                                                                       @"inputIntensity", @0.9, nil];
}

- (CIFilter *)sepiaFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CISepiaTone" withIntensity:@0.8 forImage:self.thumbnailImage];
}

- (CIFilter *)bloomFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CIBloom" withIntensity:@1.0 forImage:self.thumbnailImage];
}

- (CIFilter *)hueFilterForImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:kCIInputImageKey, self.thumbnailImage, @"inputAngle", @80, nil];
}

- (CIFilter *)invertFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CIColorInvert" forImage:self.thumbnailImage];
}

- (CIFilter *)posterizeFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CIColorPosterize" forImage:self.thumbnailImage];
}

- (CIFilter *)dotScreenFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CIDotScreen" forImage:self.thumbnailImage];
}

- (CIFilter *)gloomFilterForImage:(CIImage *)image
{
    return [self getFilter:@"CIGloom" withIntensity:@1.0 forImage:self.thumbnailImage];
}

- (CIFilter *)pixellateFilterForImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIPixellate" keysAndValues:kCIInputImageKey, self.thumbnailImage, @"inputScale", @7, nil];
}

- (CIFilter *)brightnessFilterForImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, self.thumbnailImage, @"inputBrightness", @0.1, nil];
}


#pragma mark - Button methods

// Each of the following methods apply a filter to the main image when they are tapped by the user:

- (IBAction)originalButtonTapped
{
    NSLog(@"Original button tapped");
    self.imageView.image = self.selectedImage;
}

- (IBAction)sepiaButtonTapped
{
    NSLog(@"Sepia button tapped");
    CIFilter *filter = [self sepiaFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)monochromeButtonTapped
{
    NSLog(@"Monochrome button tapped");
    CIFilter *filter = [self monochromeFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)bloomButtonTapped
{
    NSLog(@"Bloom button tapped");
    CIFilter *filter = [self bloomFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)hueAdjustButtonTapped
{
    NSLog(@"Hue adjust button tapped");
    CIFilter *filter = [self hueFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)invertButtonTapped
{
    NSLog(@"Invert button tapped");
    CIFilter *filter = [self invertFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)posterizeButtonTapped
{
    NSLog(@"Posterize button tapped");
    CIFilter *filter = [self posterizeFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)dotScreenButtonTapped
{
    NSLog(@"Dot screen button tapped");
    CIFilter *filter = [self dotScreenFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)gloomButtonTapped
{
    NSLog(@"Gloom button tapped");
    CIFilter *filter = [self gloomFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)pixellateButtonTapped
{
    NSLog(@"Pixellate button tapped");
    CIFilter *filter = [self pixellateFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

- (IBAction)brightnessButtonTapped
{
    NSLog(@"Brightness button tapped");
    CIFilter *filter = [self brightnessFilterForImage:self.originalImage];
    self.imageView.image = [self applyFilter:filter];
}

@end
