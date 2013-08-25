//
//  AudioProcessor.m
//  MicInput
//
//  Created by Stefan Popp on 21.09.11.
//  Copyright 2011 http://www.stefanpopp.de/2011/capture-iphone-microphone/ . All rights reserved.
//

#import "AudioProcessor.h"

#pragma mark Recording callback

static OSStatus recordingCallback(void *inRefCon, 
                                  AudioUnitRenderActionFlags *ioActionFlags, 
                                  const AudioTimeStamp *inTimeStamp, 
                                  UInt32 inBusNumber, 
                                  UInt32 inNumberFrames, 
                                  AudioBufferList *ioData) {
	
	// the data gets rendered here
    AudioBuffer buffer;
    
    // a variable where we check the status
    OSStatus status;
    
    /**
     This is the reference to the object who owns the callback.
     */
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames * 2; // sample size
    buffer.mNumberChannels = 1; // one channel
	buffer.mData = malloc( inNumberFrames * 2 ); // buffer size
	
    // we put our buffer into a bufferlist array for rendering
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
    
    // render input and check for error
    status = AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    [audioProcessor hasError:status:__FILE__:__LINE__];
    
	// process the bufferlist in the audio processor
    [audioProcessor processBuffer:&bufferList];
	
    // clean up the buffer
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}

#pragma mark Playback callback

static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {    

    }

#pragma mark objective-c class

@implementation AudioProcessor
@synthesize audioUnit, audioBuffer, gain;

-(AudioProcessor*)init
{
    self = [super init];
    if (self) {
        freq1 = 0;
        freq2 = 0;
        frequency_x = NULL;
        frequency_y = NULL;
        [self initializeAudio];
    }
    return self;
}

-(void)initializeAudio
{    
    OSStatus status;
	
	// We define the audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output; // we want to ouput
	desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
	desc.componentFlags = 0; // must be zero
	desc.componentFlagsMask = 0; // must be zero
	desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
	
	// find the AU component by description
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// create audio unit by component
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
	[self hasError:status:__FILE__:__LINE__];
	
    // define that we want record io on the input bus
    UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Input, // scope to input
								  kInputBus, // select input bus (1)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	// define that we want play on io on the output bus
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Output, // scope to output
								  kOutputBus, // select output bus (0)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	/* 
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz 
     */
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= SAMPLE_RATE;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
    
    
	// set the format on the output stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
    
	[self hasError:status:__FILE__:__LINE__];
    
    // set the format on the input stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	[self hasError:status:__FILE__:__LINE__];
	
	
	
    /**
        We need to define a callback structure which holds
        a pointer to the recordingCallback and a reference to
        the audio processor object
     */
	AURenderCallbackStruct callbackStruct;
    
    // set recording callback
	callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
	callbackStruct.inputProcRefCon = (__bridge void *)(self);

    // set input callback to recording callback on the input bus
	status = AudioUnitSetProperty(audioUnit, 
                                  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
    
    [self hasError:status:__FILE__:__LINE__];
	
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	[self hasError:status:__FILE__:__LINE__];
	
    // reset flag to 0
	flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	

    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
    */
	audioBuffer.mNumberChannels = 1;
	audioBuffer.mDataByteSize = 512 * 2;
	audioBuffer.mData = malloc( 512 * 2 );
	
	// Initialize the Audio Unit and cross fingers =)
	status = AudioUnitInitialize(audioUnit);
	[self hasError:status:__FILE__:__LINE__];
    
    NSLog(@"Started");
    
}

#pragma mark controll stream

-(void)start;
{
    // start the audio unit. You should hear something, hopefully :)
    OSStatus status = AudioOutputUnitStart(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
    delay = 30;
    countx = 0;
    county = 0;
    lastx = 0.0f;
    lasty = 0.0f;
}
-(void)stop;
{
    // stop the audio unit
    OSStatus status = AudioOutputUnitStop(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}


-(void)setFrequencies:(NSArray*)frequencies_x:(NSArray*)frequencies_y 
{
    frequency_x = frequencies_x;
    frequency_y = frequencies_y;
}

-(float)getfreq1
{
    return freq1;
}

-(float)getfreq2
{
    return freq2;
}

#pragma mark processing

-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    AudioBuffer sourceBuffer = audioBufferList->mBuffers[0];
    
    // we check here if the input data byte size has changed
	if (audioBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        // clear old buffer
		free(audioBuffer.mData);
        // assing new byte size and allocate them on mData
		audioBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
		audioBuffer.mData = malloc(sourceBuffer.mDataByteSize);
	}
    
    /**
     Here we modify the raw data buffer now. 
     In my example this is a simple input volume gain.
     iOS 5 has this on board now, but as example quite good.
     */
    int numFrames = (audioBufferList->mBuffers[0].mDataByteSize / 2);
    
    SInt16 *editBuffer = audioBufferList->mBuffers[0].mData;
    
    float *convertedSampleBuffer = (float*)malloc(sizeof(float) * numFrames);
    
    for(int i = 0; i < numFrames; i++) {
        convertedSampleBuffer[i] = (float)editBuffer[i] / 32768.0f;
    }
    
    
    float minimummagnitude = 0.003f;
    float highestx = 0;
    float highestxmagnitude = 0;
    for (int x = 0; x<frequency_x.count; x++) {
        float targetfreq = [frequency_x[x] floatValue];
        float magnitude = goertzel_mag(numFrames, targetfreq, SAMPLE_RATE, convertedSampleBuffer);
        if(magnitude > highestxmagnitude && magnitude > minimummagnitude){
            highestx = targetfreq;
            highestxmagnitude = magnitude;
        }
        
    }
    
    float highesty = 0;
    float highestymagnitude = 0;
    for (int y = 0; y<frequency_y.count; y++) {
        float targetfreq = [frequency_y[y] floatValue];
        float magnitude = goertzel_mag(numFrames, targetfreq, SAMPLE_RATE, convertedSampleBuffer);
        if(magnitude > highestymagnitude && magnitude > minimummagnitude){
            highesty = targetfreq;
            highestymagnitude = magnitude;
        }
        
    }

    //delay check for x
    
    if (countx > delay) {
        freq1 = highestx;
        countx = 0;
    }else if(highestx == lastx){
        countx++;
    }else{
        countx = 0;
        lastx = highestx;
    }
    
    
    //delay check for y
    
    if (county > delay) {
        freq2 = highesty;
        county = 0;
    }else if(highesty == lasty){
        county++;
    }else{
        county = 0;
        lasty = highesty;
    }

    data = convertedSampleBuffer;
    
    
    
    // loop over every packet
    //for (int nb = 0; nb < (audioBufferList->mBuffers[0].mDataByteSize / 2); nb++) {

            // we need more accuracy in our calculation so we calculate with doubles
            //double sample = ((double)editBuffer[nb]) / 32767.0;

    //}
    
	// copy incoming audio data to the audio buffer
	memcpy(audioBuffer.mData, audioBufferList->mBuffers[0].mData, audioBufferList->mBuffers[0].mDataByteSize);
}

#pragma mark Error handling

-(void)hasError:(int)statusCode:(char*)file:(int)line 
{
	if (statusCode) {
		printf("Error Code responded %d in file %s on line %d\n", statusCode, file, line);
        exit(-1);
	}
}


float goertzel_mag(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, float* data)
{
    int     k,i;
    float   floatnumSamples;
    float   omega,sine,cosine,coeff,q0,q1,q2,magnitude,real,imag;
    
    float   scalingFactor = numSamples / 2.0;
    
    floatnumSamples = (float) numSamples;
    k = (int) (0.5 + ((floatnumSamples * TARGET_FREQUENCY) / SAMPLING_RATE));
    omega = (2.0 * M_PI * k) / floatnumSamples;
    sine = sin(omega);
    cosine = cos(omega);
    coeff = 2.0 * cosine;
    q0=0;
    q1=0;
    q2=0;
    
    for(i=0; i<numSamples; i++)
    {
        q0 = coeff * q1 - q2 + data[i];
        q2 = q1;
        q1 = q0;
    }
    
    // calculate the real and imaginary results
    // scaling appropriately
    real = (q1 - q2 * cosine) / scalingFactor;
    imag = (q2 * sine) / scalingFactor;
    
    magnitude = sqrtf(real*real + imag*imag);
    return magnitude;
}

-(float*) getData{
    return data;
}


@end
