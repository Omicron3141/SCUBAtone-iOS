//
//  ViewController.m
//  SCUBATone
//
//  Created by Jonah Rubin on 8/3/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import "ViewController.h"
#include <math.h>
#import <AudioUnit/AudioUnit.h>


//create sine wave and buffer frequencies
OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
    
    ViewController *viewController =
    (__bridge ViewController *)inRefCon;
    
    
	double theta1 = viewController->theta1;
    double theta2 = viewController->theta2;
	double theta_increment1 = 2.0 * M_PI * viewController->freq1 / viewController->sampleRate;
    double theta_increment2 = 2.0 * M_PI * viewController->freq2 / viewController->sampleRate;
    
	// This is a mono tone generator so we only need the first buffer, we'll just superimpose the sine waves
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++)
	{
        //add the current wave to the buffer, then increment theta1 and theta two for the next wave
		buffer[frame] = sin(theta1) * amplitude + sin(theta2) * amplitude;
		
		theta1 += theta_increment1;
		if (theta1 > 2.0 * M_PI)
		{
			theta1 -= 2.0 * M_PI;
		}
        theta2 += theta_increment2;
		if (theta2 > 2.0 * M_PI)
		{
			theta2 -= 2.0 * M_PI;
		}
	}
    
    const int channel2 = 0;
	Float32 *buffer2 = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	
	// Store the theta back in the view controller
	viewController->theta1 = theta1;
    viewController->theta2 = theta2;
    
	return noErr;
}








//if the application is interrupted, stop transmitting
void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	ViewController *viewController =
    (__bridge ViewController *)inClientData;
	
	[viewController stop];
}

@interface ViewController ()

@end




@implementation ViewController
@synthesize audioProcessor;
//variables for receiver


//called once when the view is loaded
- (void)viewDidLoad
{
        [super viewDidLoad];
    
        //initialize the default messages
        NSArray *messages = [[NSUserDefaults standardUserDefaults] objectForKey:@"messages"];
        if (messages != NULL) {
            _messages = messages;
        }else if ([_messages objectAtIndex:0] == nil) {
            _messages = @[ @"EMERGENCY!", @"Are you OK?", @"I'm OK/Affirmative.",
                           @"Negative", @"Need help, non emergency.", @"Found something neat!", @"I'm lost!", @"I'm done/ready", @"I need more time.", @"Boat is moving.", @"Let's go this way.", @"I am low on air.", @"Take picture.", @"I need to poop.", @"Get to the Choppa!", @"Sharknado!"];

        }
        //frequencies are organized by x- and y-axis on the DTMF table
        _frequenciesx = @[ @1209.0f, @1336.0f, @1477.0f,
                       @1633.0f];
    
        _frequenciesy = @[ @697.0f, @770.0f, @852.0f,
                            @941.0f];
    
    
    freq1 = [_frequenciesx[0] floatValue];
    freq2 = [_frequenciesy[0] floatValue];
    
    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(100, 120, 560, 200)];
    picker.delegate = self;
    picker.showsSelectionIndicator = YES;
    [self.view addSubview:picker];
    picker.dataSource = self;
    picker.delegate = self;
    
    transmitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [transmitButton addTarget:self
               action:@selector(transmit)
     forControlEvents:UIControlEventTouchUpInside];
    [transmitButton setTitle:@"Transmit" forState:UIControlStateNormal];
    transmitButton.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [transmitButton setCenter:CGPointMake(360, 340)];
    [self.view addSubview:transmitButton];
    
    changeMessageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [changeMessageButton addTarget:self
                       action:@selector(changeMessages)
             forControlEvents:UIControlEventTouchUpInside];
    [changeMessageButton setTitle:@"Change Messages" forState:UIControlStateNormal];
    changeMessageButton.frame = CGRectMake(590.0, 20.0, 160.0, 40.0);
    [self.view addSubview:changeMessageButton];
    
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"reef.jpg"]]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 385, 600, 30)];
    [self.view addSubview:label];
    
    freqlabel1 = [[UILabel alloc] initWithFrame:CGRectMake(40, 70, 200, 30)];
    [freqlabel1 setCenter:CGPointMake(300, 400)];
    freqlabel1.text = @"Frequency 1:      0HZ";
    [self.view addSubview:freqlabel1];
    
    freqlabel2 = [[UILabel alloc] initWithFrame:CGRectMake(40, 70, 455, 30)];
    [freqlabel2 setCenter:CGPointMake(605, 400)];
    freqlabel2.text = @"Frequency 2:       0HZ";
    [self.view addSubview:freqlabel2];
    
    
    messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 600, 560, 100)];
    [messageLabel setNumberOfLines:1];
    [messageLabel setFont:[UIFont fontWithName:@"Arial" size:100]];
    [messageLabel setAdjustsFontSizeToFitWidth: YES];
    [self.view addSubview:messageLabel];
    
    
    //initialize the sound wave graph subview
    graph = [[GraphView alloc] initWithFrame:CGRectMake(100, 410, 600, 300)];
    
    [self.view addSubview:graph];
    
    //the primary variable for a little hack to ensure that the 5-second auto-timeout for does not accidentally reactivate a disabled transmission
    buttonPressIsEndOfTimer = NO;
    
    //set the sample rate for the tonal generator 20100 seems to work well
    sampleRate = 20100;
    
    //schedule the graph to update every 0.1 seconds
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:graph selector:@selector(setNeedsDisplay) userInfo:nil repeats:YES];
    
    //OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, self);
	//if (result == kAudioSessionNoError)
	//{
	//	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	//	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	//}
    
    audioProcessor = [[AudioProcessor alloc] init];
    [audioProcessor start];
    [audioProcessor setFrequencies:_frequenciesx :_frequenciesy];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getIncomingTransmissionsFromData) userInfo:nil repeats:YES];
    
    
    

}


// meathods to provide data to the picker
#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
    [picker reloadAllComponents];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return _messages.count;
    [picker reloadAllComponents];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return _messages[row];
    [picker reloadAllComponents];
}

//methods to recieve data from the picker
#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    freq1 = [_frequenciesx[row%4] floatValue];
    freq2 = [_frequenciesy[((int)(row/4))] floatValue];
    
    if(transmitting){
        freqlabel1.text = [NSString stringWithFormat:@"Frequency 1:  %iHZ", (int)freq2];
        freqlabel2.text = [NSString stringWithFormat:@"Frequency 2: %iHZ", (int)freq1];
        [graph setFrequencies:freq1 :freq2];
    }
    
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//take the set frequencies at begin emmiting the tone
- (void) transmit{
    if (!transmitting){
        //if you are not already tansmitting, start transmitting
        [self createToneUnit];
		
		// Stop changing parameters on the unit
		OSErr err = AudioUnitInitialize(toneUnit);
		NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
		
		// Start playback
		err = AudioOutputUnitStart(toneUnit);
		NSAssert1(err == noErr, @"Error starting unit: %ld", err);
		
        
        
        [transmitButton setTitle:@"Stop Transmitting" forState:UIControlStateNormal];
        transmitting = YES;
        
        
        transmitTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(transmitendoftimer) userInfo:nil repeats:NO];
        
        
        
        
        freqlabel1.text = [NSString stringWithFormat:@"Frequency 1:  %iHZ", (int)freq2];
        freqlabel2.text = [NSString stringWithFormat:@"Frequency 2: %iHZ", (int)freq1];
        
        [graph setFrequencies:freq1 :freq2];
        buttonPressIsEndOfTimer = YES;
        
    }else{
        //if you are transmitting, stop
        AudioOutputUnitStop(toneUnit);
		AudioUnitUninitialize(toneUnit);
		AudioComponentInstanceDispose(toneUnit);
		toneUnit = nil;
        
        [transmitButton setTitle:@"Transmit" forState:UIControlStateNormal];
        transmitting = NO;
        freqlabel1.text = [NSString stringWithFormat:@"Frequency 1:      0HZ", (int)freq2];
        freqlabel2.text = [NSString stringWithFormat:@"Frequency 2:     0HZ", (int)freq1];
        [graph setFrequencies:0 :0];
        buttonPressIsEndOfTimer = NO;
        [transmitTimer invalidate];
        transmitTimer = nil;
    }
    
}

//a secondary transmit method to catch timeout calls and prevent accidental reactivation of disabled transmissions
- (void) transmitendoftimer{
    if (transmitting && buttonPressIsEndOfTimer) {
        [self transmit];
    }
}

//stuff I stole from the internet
- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %ld", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %ld", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
}


- (void)stop
{
	if (toneUnit)
	{
		[self transmit];
	}
}

- (void)viewDidUnload {
    
}

-(void) changeMessages{
    messageView = [ChangeMessageView alloc];
    [messageView setsubMessages:_messages];
    messageView = [messageView initWithFrame: CGRectMake(0.0, 0.0, 840.0, 960.0)];
    [self.view addSubview:messageView];
}

-(void) getNewMessages{
    _messages = [messageView getMessages];
    [picker reloadAllComponents];
}


-(void) getIncomingTransmissionsFromData{
    if (!transmitting) {
        float freqx = [audioProcessor getfreq1];
        float freqy = [audioProcessor getfreq2];
        int freqxid = -1;
        int freqyid = -1;
        for (int i = 0; i<_frequenciesx.count; i++) {
            if (freqx == [_frequenciesx[i] floatValue]){
                freqxid = i;
            }
        }
        for (int i = 0; i<_frequenciesy.count; i++) {
            if (freqy == [_frequenciesy[i] floatValue]){
                freqyid = i;
            }
        }
        if(freqyid<0 || freqxid<0){
            messageLabel.text = @"";
            return;
        }
        NSString *message = _messages[(int)((freqyid*4)+(freqxid))];
        NSLog(message);
        messageLabel.text = message;

    }
}




@end
