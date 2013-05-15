//
//  NetworkingHelper.h
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/14/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkingHelperDelegate;

@interface NetworkingHelper : NSObject
@property (nonatomic, weak) id<NetworkingHelperDelegate> delegate;
+ (id)sharedNetworkingHelper;
- (void)latestUploads;
- (void)postImageToAppSpot:(UIImage *)image;
- (BOOL)noInternetConnection;

@end


@protocol NetworkingHelperDelegate <NSObject>

@optional
- (void)helperFinishedFetchingResults:(NSArray *)results;
- (void)helperFinishedPostingImage;

@end