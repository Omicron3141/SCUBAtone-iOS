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

-(void) setData: (NSMutableArray*) d{
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
        for (int i = 0; i < 4; i++) {
            NSMutableArray *newdata = [NSMutableArray array];
            for (int j = 0; j < data.count; j+=1) {
                float d = [data[j] floatValue];
                if (j>60) {
                    d+=([data[j-30] floatValue]-[data[j-60] floatValue])/20;

                }
               [newdata addObject:[NSNumber numberWithFloat:d]];
            }
            data = newdata;
        }
        for (int i = 0; i < data.count; i+=10) {
            CGContextMoveToPoint(context, newpos.x, newpos.y);
            float d = [data[i] floatValue];
            newpos = CGPointMake(i/10+100, 80-(0.5f*d));
            CGContextAddLineToPoint(context, newpos.x, newpos.y);
            
        }
        CGContextAddLineToPoint(context, 550, 80);
        CGContextSetLineWidth(context, 2);
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGContextStrokePath(context);
    }
}



@end
