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
#import "AudioProcessor.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TransmissionGraphView.h"


#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 44100.00


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
    TransmissionGraphView *tgraph;
    NSTimer *transmitTimer;
    
    UILabel *messageLabel;
    
    // Audio Unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
    

    
    
    



    
@public
    double sampleRate;
    float freq1;
    float freq2;
	double theta1;
    double theta2;

}


-(void) stop;
-(void) getNewMessages;
int initAudioSession();
-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;


// error managment
-(void)hasError:(int)statusCode:(char*)file:(int)line;

@property (retain, nonatomic) AudioProcessor *audioProcessor;
@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (strong, nonatomic) NSArray *messages;
@property (strong, nonatomic) NSArray *frequenciesy;
@property (strong, nonatomic) NSArray *frequenciesx;


@end


