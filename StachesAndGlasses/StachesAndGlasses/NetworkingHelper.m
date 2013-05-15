//
//  NetworkingHelper.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/14/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  This is a utility singleton class that contains most of the networking functionality for this app.  It can
//  detect whether an internet conneciton is present, download images from the web, and post an image to the
//  web.  The images that are downloaded can be found at stachesandglasses.appspot.com/user/[USERNAME]/web/.
//  The username 'rtimpone' is hardcoded into this class for the purposes of this project.  This class has a
//  delegate, which can receive messages from NetworkingHelper when certain tasks such as uploading or
//  downloading are completed.  The uploading code is mostly unchanged from some sample code that was provided
//  by the professor.  


#import "NetworkingHelper.h"
#import "GTMHTTPFetcher.h"
#import "Reachability.h"

#define API_KEY @"rtimpone"
#define API_URL @"http://stachesandglasses.appspot.com"

@implementation NetworkingHelper

#pragma mark Networking API

// This class is a singleton - every class shares the same instance of NetworkingHelper
+ (id)sharedNetworkingHelper
{
    static NetworkingHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[NetworkingHelper alloc] init];
    });
    return helper;
}

// Uses Apple's Reachability code to detect whether an internet connection is available or not
// Used the post at stackoverflow.com/questions/8812459 for help with this
- (BOOL)noInternetConnection
{
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [internetReachability currentReachabilityStatus];
    return status == NotReachable ? YES : NO;
}

// Gets the latest image uploads from a user and sends them to the delegate
- (void)latestUploads
{
    // constructs the url given the api url and username defined above
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/json/",API_URL,API_KEY];
    NSURL *url = [NSURL URLWithString:urlString];
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:[NSURLRequest requestWithURL:url]];
    [myFetcher beginFetchWithCompletionHandler:^(NSData *retrievedData, NSError *error) {
        
		if (error != nil) {
            NSLog(@"Error fetching JSON data: %@",error);
            
		} else {
            
            // the JSON data retrieved from the web
            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:retrievedData options:kNilOptions error:&error];

            // an array that will hold the images
            NSMutableArray *images = [@[] mutableCopy];
            
            for (NSDictionary *image in jsonData[@"results"]) {
                
                // gets the image URL
                NSString *imageUrlString = [NSString stringWithFormat:@"%@/%@",API_URL,image[@"image_url"]];
                NSURL *imageUrl = [NSURL URLWithString:imageUrlString];
                
                // gets the contents of the page (to check if the page says 'No image', indicating an image is not present)
                NSString *contents = [NSString stringWithContentsOfURL:imageUrl encoding:NSUTF8StringEncoding error:nil];

                // if the page doesn't say 'No image', creates the image and adds it to the array
                if (![contents isEqualToString:@"No image"]) {
                    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
                    [images addObject:[UIImage imageWithData:imageData]];
                }
            }
            
            // sends the images to the delegate
            if ([self.delegate respondsToSelector:@selector(helperFinishedFetchingResults:)]) {
                NSLog(@"Sending images to delegate");
                [self.delegate helperFinishedFetchingResults:images];
            }
        }
	}];
}

// Posts a given image to stachesandglasses.appspot.com for a given username
- (void)postImageToAppSpot:(UIImage *)image
{
    // done in a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSString *urlString = [NSString stringWithFormat:@"%@/post/%@/",API_URL,API_KEY];
        [self uploadImage:image withName:nil toURL:urlString];
        
        // done back on the main thread when the background thread is finished
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.delegate helperFinishedPostingImage];
        });
    });
}

// Uploads an image to the page at stachesandglasses.appspot.com that corresponds to the username
// This code is mostly unchanged from some sample code that waas provided by the professor
- (BOOL)uploadImage:(UIImage *)image withName:(NSString *)fileName toURL:(NSString*)urlString
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"0x0hHai1CanHazB0undar135";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding: NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Disposition: form-data; name=\"caption\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"THIS_IS_AN_OPTIONAL_CAPTION" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"%@\"\r\n",@"something"]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData: UIImageJPEGRepresentation(image,100)];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    // Send the request
    NSLog(@"Request: %@",request);
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSLog(@"Return String: %@",returnString);
    
    return YES;
}

@end
