//
//  PaintView.h
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/13/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PaintViewDelegate;

@interface PaintView : UIView

@property (nonatomic, weak) id <PaintViewDelegate> delegate;
@property (strong, nonatomic) UIColor *lineColor;

- (void)clearPaintView;

@end


@protocol PaintViewDelegate <NSObject>

- (void)paintView:(PaintView *)paintView finishedTrackingPathInRect:(CGRect)paintedArea;

@end