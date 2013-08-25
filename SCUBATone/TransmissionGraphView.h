//
//  TransmissionGraphView.h
//  SCUBATone
//
//  Created by Jonah Rubin on 8/19/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TransmissionGraphView : UIView

{
    float *data;
    
}
-(id) initWithFrame:(CGRect)frame;

-(void) setData: (float*) d;

@end
