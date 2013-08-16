//
//  ViewController.h
//  SCUBATone
//
//  Created by Jonah Rubin on 8/3/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>
#import "GraphView.h"
#import "ChangeMessageView.h"


@interface ViewController : UIViewController
<UIPickerViewDelegate, UIPickerViewDataSource>
{

    UIPickerView *picker;
    UIButton *transmitButton;
    UILabel *titlelabel;
    
    UIButton *changeMessageButton;
    
    ChangeMessageView *messageView;
    
    AudioComponentInstance toneUnit;
    BOOL transmitting;
    BOOL buttonPressIsEndOfTimer;
    UILabel *freqlabel1;
    UILabel *freqlabel2;
    GraphView *graph;
    NSTimer *transmitTimer;
    
    
    



    
@public
    double sampleRate;
    float freq1;
    float freq2;
	double theta1;
    double theta2;

}


-(void) stop;
-(void) getNewMessages;
@property (strong, nonatomic) NSArray *messages;
@property (strong, nonatomic) NSArray *frequenciesy;
@property (strong, nonatomic) NSArray *frequenciesx;


@end


