# RMSAudio
## Objective-C AudioEngine for OSX and iOS

RMSAudio is an experiment in designing a simple and comprehensive audio management structure in Objective-C for the Mac OS family. The design principles are based on the following logic: 

1. Connecting objects should be as simple as the real world equivalents, in other words, no AUGraph, no separate render trees etc. Connecting objects automatically is the tree. Nodes and leaves are exponents of a single parent. It is as easy to connect a single object, as it is to connect an entire tree.
  * object management is done in Objective-C, 
  * rendering is done in C, 
  * hooks are used to maintain inheritance,
  * object existence is guarded for the audiothread. 

2. Writing experimental code to test audio algorithms is extremely easily accomplished and does not require setting up a full environment and writing an entire audiounit.

As an example, PlayThru (from mic to output) is as simple as: 

    self.audioOutput = [RMSOutput defaultOutput];
    self.audioOutput.source = [RMSInput defaultInput];
   
That just works. It even works with differing sampleRates between input and output, as the RMSInput has a simple linear-interpolating ringbuffer build in, and the output object automatically sets the samplerate of its source. Setting the sampleRate of a source always refers to the “outputscope” of that source. 

If a more sophisticated algorithm would be desired for sampleRate conversion, it is just as simple to add the Varispeed audiounit in between input and output: 
```obj-c
RMSSource *source = [RMSInput defaultInput];

if (source.sampleRate != self.audioOutput.sampleRate)
{ source = [RMSAudioUnitVarispeed instanceWithSource:source]; }

self.audioOutput.source = source;
```
Which builds a simple tree: input->varispeed->output

## Writing a custom RMSSource
To create your own RMSSource you need to implement a C callback function within the implementation scope. In template form it typically looks like this:
```obj-c
static OSStatus renderCallback(
	void                       *refCon,
	AudioUnitRenderActionFlags *actionFlagsPtr,
	const AudioTimeStamp       *timeStampPtr,
	UInt32                     busNumber,
	UInt32                     frameCount,
	AudioBufferList            *bufferListPtr)
{
	__unsafe_unretained MyRMSSource *rmsObject =
	(__bridge __unsafe_unretained MyRMSSource *)refCon;

	OSStatus result = noErr;
	
	// Fill buffers in bufferListPtr 

	return result;
}


+ (AURenderCallback) callbackPtr
{ return renderCallback; }

```

The class globalscope callbackPtr method allow "new" and "init" to do all the required initialization. Getting your code to run then is as simple as:

```obj-c
self.audioOutput.source = [MyRMSSource new];
```
