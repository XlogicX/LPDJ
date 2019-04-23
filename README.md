# LPDJ
Little Propeller DJ

# Description
This is based off of the PCM driver I wrote 10 years ago, it is a 'fork.' I have decided I want to move away from using statically coded samples. Not just because they can begin to take up a lot of space, but they are less flexible

My goal with this driver is to dynamically generate sample data; have a routine generate the wave shape on the fly (square, sine, saw, triangle, pulse, etc...). One example of flexibility is for duty cycles. This is a known effect for pulse waves, but perhaps it could apply to sine, saw and others).

I also plan to review my old code and debug and refactor where applicable.
