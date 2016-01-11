# RMSAudio
Objective-C AudioEngine for OSX and iOS

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

If a more sophisticated algorithm would be desired for sampleRate conversion, it is just a simple to add the Varispeed audiounit in between input and output: 
```obj-c
RMSSource *source = [RMSInput defaultInput];

if (source.sampleRate != self.audioOutput.sampleRate)
{ source = [RMSAudioUnitVarispeed instanceWithSource:source]; }

self.audioOutput.source = source;
```
Which builds a simple tree: input->varispeed->output
