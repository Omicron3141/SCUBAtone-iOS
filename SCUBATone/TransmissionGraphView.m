//
//  TransmissionGraphView.m
//  SCUBATone
//
//  Created by Jonah Rubin on 8/19/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import "TransmissionGraphView.h"


@implementation TransmissionGraphView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

-(void) setData: (float*) d{
    data = d;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    
    if (data != NULL) {
        CGPoint newpos = CGPointMake(0, 80);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //CGContextMoveToPoint(context, 0, 100);
        CGContextBeginPath(context);
        for (int i = 0; i < 6000; i+=10) {
            CGContextMoveToPoint(context, newpos.x, newpos.y);
            float d = data[i];
            newpos = CGPointMake(i/10, 80-(100.0f*d));
            CGContextAddLineToPoint(context, newpos.x, newpos.y);
            
        }
        CGContextAddLineToPoint(context, 550, 80);
        CGContextSetLineWidth(context, 2);
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGContextStrokePath(context);
    }
}



@end
