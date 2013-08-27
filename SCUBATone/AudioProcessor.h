//
//  AudioProcessor.h
//  MicInput
//
//  Created by Stefan Popp on 21.09.11.
//  Copyright 2011 http://http://www.stefanpopp.de/2011/capture-iphone-microphone//2011/capture-iphone-microphone/ . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 44100.00

@interface AudioProcessor : NSObject
{
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
    
    // gain
    float freq1;
    float freq2;
    NSArray *frequency_x;
    NSArray *frequency_y;
    NSMutableArray *smoothedData;
    NSMutableArray *data;

    
    int countx;
    int county;
    int delay;
    float lastx;
    float lasty;
}

@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) float gain;

-(AudioProcessor*)init;

-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;

// control object
-(void)start;
-(void)stop;

// gain
-(void)setFrequencies:(NSArray*)frequencies_x:(NSArray*)frequencies_y;
-(float)getfreq1;
-(float)getfreq2;
-(float*) getData;

// error managment
-(void)hasError:(int)statusCode:(char*)file:(int)line;

//fft
-(NSMutableArray*) FFTConvert: (float*) buffer: (float) startfreq: (float) endfreq: (int) numSamples:(int) samplingRate;

@end
