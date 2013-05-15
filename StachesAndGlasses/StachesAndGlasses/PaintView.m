//
//  PaintView.m
//  StachesAndGlasses
//
//  Created by Rob Timpone on 5/13/13.
//  Copyright (c) 2013 Rob Timpone. All rights reserved.
//
//  The PaintView class is a custom UIView that tracks paths drawn by the user's finger and draws them onscreen.
//  The class sends information to its delegate when a path is complete that allows the delegate to merge
//  the PaintView with another image.  As an optimization, as the user is drawing, only the 'dirty' area
//  (the area directly surrounding the newest touches) is redrawn.  This results in higher performance drawing
//  than would be available otherwise.  


#import "PaintView.h"

@interface PaintView()

@property (strong, nonatomic) UIBezierPath *path;   // the path that will track touch points
@property (nonatomic) CGRect trackingDirty;         // a rect that will encompass the area that is touched

@end


// settings for drawing the UIBezierPath
#define LINE_WIDTH 15
#define LINE_CAP_STYLE kCGLineCapRound
#define LINE_JOIN_STYLE kCGLineJoinRound

@implementation PaintView

// called when a touch is first detected on the paint view
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Paint view - touches began");
    
    // sets up self.path as a new bezier path with settings defined in the #define statements
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = LINE_WIDTH;
    self.path.lineCapStyle = LINE_CAP_STYLE;
    self.path.lineJoinStyle = LINE_JOIN_STYLE;
    
    // sets the initial location of the path to the location of one of the touches
    UITouch *touch = [touches anyObject];
    [self.path moveToPoint:[touch locationInView:self]];
    
    // sets the initial trackingDirty rect to the area around the initial touch
    CGPoint touchPoint = [touch locationInView:self];
    self.trackingDirty = CGRectMake(touchPoint.x-10, touchPoint.y-10, 20, 20);
}

// called when the touches have moved and the finger has not lifted yet
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // creates a 'dirty' rect that encompasses the area around the prevoius touch and the current touch
    CGPoint prevPoint = CGPathGetCurrentPoint(self.path.CGPath);
    CGPoint currPoint = [[touches anyObject] locationInView:self];
    CGRect dirty = [self segmentBoundsFrom:prevPoint to:currPoint];
    
    // unions the dirty rect with the cumulative trackingDirty rect
    self.trackingDirty = CGRectUnion(dirty, self.trackingDirty);
    
    // extends self.path from its current point to the location of the new touch
    UITouch *touch = [touches anyObject];
    [self.path addLineToPoint:[touch locationInView:self]];
    
    // updates the UI only for the area encompasses in the dirty rect defined above
    [self setNeedsDisplayInRect:dirty];
}

// called when the finger is lifted
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Paint view - touches ended");
    
    // extends self.path from its current point to the location of the new touch
    UITouch *touch = [touches anyObject];
    [self.path addLineToPoint:[touch locationInView:self]];
    
    // updates the UI for the entire paint view
    [self setNeedsDisplay];
    
    // lets the delegate know that the paint view is finished tracking a path, and passes the 'dirty tracking
    // rect', which represents the area that was painted
    [self.delegate paintView:self finishedTrackingPathInRect:self.trackingDirty];
}

// draws the path that is currently being tracked on the paint view
- (void)drawRect:(CGRect)rect
{
    // sets the color to the current line color and strokes the path
    [self.lineColor set];
    [self.path stroke];
}

// create a new rect that is the combination of the two points, with a buffer of +/- 10 points on each point
- (CGRect)segmentBoundsFrom:(CGPoint)point1 to:(CGPoint)point2
{
    CGRect dirtyPoint1 = CGRectMake(point1.x-10, point1.y-10, 20, 20);
    CGRect dirtyPoint2 = CGRectMake(point2.x-10, point2.y-10, 20, 20);
    return CGRectUnion(dirtyPoint1, dirtyPoint2);
}

// reset the properties used to track a path and update the UI
- (void)clearPaintView
{
    self.trackingDirty = CGRectNull;
    [self.path removeAllPoints];
    [self setNeedsDisplay];
}


@end
