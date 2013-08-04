//
//  GraphView.h
//  SCUBATone
//
//  Created by Jonah Rubin on 8/4/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphView : UIView

{
    float freq1;
    float freq2;
    int offset;
    
}
-(id) initWithFrame:(CGRect)frame;

-(void) setFrequencies: (float) frequency1: (float) frequency2;

@end
