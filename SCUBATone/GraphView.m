//
//  GraphView.m
//  SCUBATone
//
//  Created by Jonah Rubin on 8/4/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
            self.backgroundColor = [UIColor clearColor];
        offset = 0;

    }
    return self;
}

-(void) setFrequencies: (float) frequency1: (float) frequency2{
    freq1 = frequency1;
    freq2 = frequency2;
    offset = 0;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{

    CGPoint newpos = CGPointMake(550, 80);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextMoveToPoint(context, 0, 100);
    CGContextBeginPath(context);
    for (int i = 550; i > 0; i-=2) {
        CGContextMoveToPoint(context, newpos.x, newpos.y);
        newpos = CGPointMake(i, 30*sin(freq1*(i-offset))+30*sin(freq2*(i-offset)) + 80);
        CGContextAddLineToPoint(context, newpos.x, newpos.y);
        
    }
    CGContextAddLineToPoint(context, 0, 80);
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextStrokePath(context);
    offset -= 20;
}
 


@end
