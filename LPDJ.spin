{{
PCM Driver - 1-16 bit (can be modified on the fly for effects)
AUTHOR: XlogicX
Copyright (c) 2009 (MIT Terms of use; see end of file)
LAST MODIFIED: 9.24.15
VERSION 2.5
NOTE, this code is a mix of the Spin language, and Assembly.
The Assembly is what is doing the work
The Spin is effectively the API to play a note
If used in Propeller IDE, the correct file extension would be .spin

••••••••••••••••••••••••••••••••••••••••••••••••••••••  Description ••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
This is a 16-bit, 4-channel, dynamic-sample based audio driver.
Meant to be used at 80 Mhz

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx     Usage    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
You will be using the higher level API call of PlayNote.
It takes input of what Channel, frequency/note, volume, bit quality, garbledness, ors, duration, and sample / waveshape you will want to play

This is the format: PlayNote (chan, pitch, vol, Wqual, garb, dur, waveshape)

-chan can take values 1, 2, 3, and 4
-The pitch field starts at 1; the highest frequency. The larger this number gets, the lower the pitch will be
-the vol field starts at 0, the loudest. 1 is half as loud, 2 is half that, and so on. Although more precision could be desired,
 I prefer the low clock usage of a simple right shift, instead of complicated division; clocks eat at my higher frequencies.
-the quality field starts at 0 for the highest quality. The lowest quality goes up to 29, it is basically a square wave at 1-bit
 quality. For this very reason, I will probably not include a sample for a square wave; it's just pointless.
-the duration field is used for how long to play the note, the larger the value, the longer the note will be played
-the waveshape field allows you to pick a sample. The first sample in the data area would be number 1, the next number 2, and so
 on.
-the garble field, uhh, I don't know, it garbles the sound up a little.
-the ors field applies a user specified OR mask to audio

Explanation for gratuitous Note CON section:
As you can see, I have conversions for bass, tenor, alto, and soprano notes. There are pros and cons for which you decide to use
-On the Bass end:
  Pro: This is where the sound has the most 'piece' resloution, it has 128 pieces of data per shape, which means it has the
       least sub-harmonics. This is most noticeable in a low frequency sine wave
  Con: Limited upper range; you can't get any higher than 2,982 Hz
  Con: Precision is reduced; an A note in the 3rd octave is 220Hz, however, the closest value the bass values can play is 213Hz
-On the soprano end:
  Pro: Great upper range; highest pitch is 23,860Hz.
  Pro: Precision is also great compared to bass end; the 220Hz A note is executed as 220.93.
  Con: Greatly reduced piece quality; there would only be 16 pieces/values for each shape
-Discussion: Does any of this matter? Kind of, but not greatly. If you want notes in an upper range and for them to be in tune,
 then go with soprano. It's actually harder to hear degraded audio at higher notes anyway (I tested this). If you need really
 low bassy notes to sound clear without subharmonics, you will want to opt for the bass and tenor samples. The quality is most
 notable in smoother/slower changing wave shapes though, such as sine and triangle. On the other end, if your using square
 waves, I don't see a reason not to use soprano for all of the notes. Another note to make is that the notes do tend to get
 out of tune the higher the notes get (for any of the range of samples).
-Columns commented in CON section: I have a column for what the actual frequency of the note should be. A column for what
 frequency the driver is actually playing, and another column of "tolerance" showing a ratio of how close they are in
 relation. Anything in the thousandth digit and even hundredth digit is probably fine to an extent, but I wouldn't recommend
 using the notes that have values in the tenth digit, unless you want your music to sound horrible.

***************************************************   Change History   ***********************************************************

Ver 2.5 [9-3-2009]:
  •Had to re-write everything when I found out about crta and frqa; it does PWM for me, seamlessly. The main assembly code now
   does PCM, successfully.

}}
  
DAT
'Channels
chan1         long      0[128]                                                                 
chan2         long      $11111111[128]
chan3         long      $22222222[128]
chan4         long      $33333333[128]

VAR           
                      'par offset
long    freq                        'variable that controls wave frequency (has limits of how low it can be [8])
long    freq2         '4             x
long    freq3         '8             x
long    freq4         '12            x
long    volume        '16            lower value equals larger volume
long    volume2       '20            x
long    volume3       '24            x
long    volume4       '28            x
long    quality       '32            0 = 16-bit, 1 = 15-bit, 2 = 14-bit....
long    data_adr      '36            address of channel data starting location
long    garble        '40            garble effect
long    comp_flag     '44            this is an or mask to apply to audio
long    duration      '48            how long to play the note / times to play sample
long    duration2     '52            x
long    duration3     '56            x
long    duration4     '60            x
long    shape         '64            what type or shape of wave (sine, saw, etc...)
long    shape2        '68            x
long    shape3        '72            x
long    shape4        '76            x
long    DeComFlags    '80            flag for what channels to decode

long    mix1_adr      '84            'memory location to the mix channels
long    mix2_adr      '88            x
long    mix3_adr      '92            x
long    mix4_adr      '96            x
long    mix_out_adr   '100           x

long    ch1_done      '104           'flags for channel being done playing
long    ch2_done      '108           x
long    ch3_done      '112           x
long    ch4_done      '116           x

long    pin           '120           'what pin to send the audio to

'Instrument Variables
'  Seperate variables are used for each channel. I could use just one set, but
'  then we would have to wait about 8,000 cycles (about how long a cog takes
'  to get loaded) until we could load the next one, due to variables paving over
'  before the cog is even ready for the values.
long    duty
long    divisions
long    table_adr
long    duty2
long    divisions2
long    table_adr2
long    duty3
long    divisions3
long    table_adr3
long    duty4
long    divisions4
long    table_adr4

long    pitch_bal                    'variable used to even out duration based on pitch
long    dur_div                      'what number equals a second with dur parameter. For example, if dur_div is 100, a
                                     'value of 50 passed to the dur param would be half a second.
long    w_note2

long    dutyval

long    rand
long    rchoice
long    index
long    voltage

PUB Start (audio_pin, d_div)
 
  data_adr    := @chan1         'put address of starting address chan1 in data_adr
  pin := audio_pin
  dur_div := d_div
 
  'some initialization of values, arbitrary values.
  
  freq      := $0010
  freq2     := $0010
  freq3     := $0010
  freq4     := $0010
  quality   := 13
  ch1_done   := 1
  ch2_done   := 1
  ch3_done   := 1
  ch4_done   := 1

  mix1_adr :=  data_adr
  mix2_adr :=  data_adr + $200
  mix3_adr :=  data_adr + $400
  mix4_adr :=  data_adr + $600

  cognew(@Mixer, @freq)         'start the mixer cog
 
  cognew(@PCM, @freq)           'start the PCM cog 

PUB Silent
  volume := volume2 := volume3 := volume4 := 20

PUB PlayNote (chan, pitch, vol, Wqual, garb, ors, dur)

  'dur convert
  pitch_bal := pitch
  pitch_bal := 2982 / pitch_bal
  dur := (dur * pitch_bal) / dur_div
  
  case chan
    1:
      freq       := pitch
      volume     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors
      duration   := dur
      DecomFlags := %0001
      ch1_done   := 0
      return
    2:
      freq2       := pitch
      volume2     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors        
      duration2   := dur
      DecomFlags := %0010
      ch2_done   := 0
      return
    3:
      freq3       := pitch
      volume3     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors             
      duration3   := dur
      DecomFlags := %0100
      ch3_done   := 0
      return
    4:
      freq4       := pitch
      volume4     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors             
      duration4   := dur
      DecomFlags := %1000
      ch4_done   := 0

PUB PulseWave(channel, dut, divs)
  case channel
    1:
      cognew(@InstPulse, @duty)
      duty := dut
      if duty < 0
        duty := 8
      if duty > 16
       duty := 8
      divisions := divs
      if divisions < 0
        divisions := 0
      if divisions > 6
        divisions := 0
      table_adr := @chan1
    2:
      cognew(@InstPulse, @duty2)
      duty2 := dut
      if duty2 < 0
        duty2 := 8
      if duty2 > 16
       duty2 := 8
      divisions2 := divs
      if divisions2 < 0
        divisions2 := 0
      if divisions2 > 6
        divisions2 := 0
      table_adr2 := @chan2
    3:
      cognew(@InstPulse, @duty3)
      duty3 := dut
      if duty3 < 0
        duty3 := 8
      if duty3 > 16
       duty3 := 8
      divisions3 := divs
      if divisions3 < 0
        divisions3 := 0
      if divisions3 > 6
        divisions3 := 0
      table_adr3 := @chan3
    4:
      cognew(@InstPulse, @duty4)
      duty4 := dut
      if duty4 < 0
        duty4 := 8
      if duty4 > 16
       duty4 := 8
      divisions4 := divs
      if divisions4 < 0
        divisions4 := 0
      if divisions4 > 6
        divisions4 := 0
      table_adr4 := @chan4

PUB TriangleWave(channel, dut, divs)
  case channel
    1:
      cognew(@InstTriangle, @duty)
      duty := dut
      if duty < 0
        duty := 8
      if duty > 16
       duty := 8
      divisions := divs
      if divisions < 0
        divisions := 0
      if divisions > 6
        divisions := 0
      table_adr := @chan1
    2:
      cognew(@InstTriangle, @duty2)
      duty2 := dut
      if duty2 < 0
        duty2 := 8
      if duty2 > 16
       duty2 := 8
      divisions2 := divs
      if divisions2 < 0
        divisions2 := 0
      if divisions2 > 6
        divisions2 := 0
      table_adr2 := @chan2
    3:
      cognew(@InstTriangle, @duty3)
      duty3 := dut
      if duty3 < 0
        duty3 := 8
      if duty3 > 16
       duty3 := 8
      divisions3 := divs
      if divisions3 < 0
        divisions3 := 0
      if divisions3 > 6
        divisions3 := 0
      table_adr3 := @chan3
    4:
      cognew(@InstTriangle, @duty4)
      duty4 := dut
      if duty4 < 0
        duty4 := 8
      if duty4 > 16
       duty4 := 8
      divisions4 := divs
      if divisions4 < 0
        divisions4 := 0
      if divisions4 > 6
        divisions4 := 0
      table_adr4 := @chan4


PUB SineWave(channel, dut, divs)
  case channel
    1:
      cognew(@InstSine, @duty)
      duty := dut
      if duty < 1
        duty := 1
      if duty > 15
       duty := 15
      divisions := divs
      if divisions < 0
        divisions := 0
      if divisions > 6
        divisions := 0
      table_adr := @chan1
    2:
      cognew(@InstSine, @duty2)
      duty2 := dut
      if duty2 < 1
        duty2 := 1
      if duty2 > 15
       duty2 := 15
      divisions2 := divs
      if divisions2 < 0
        divisions2 := 0
      if divisions2 > 6
        divisions2 := 0
      table_adr2 := @chan2
    3:
      cognew(@InstSine, @duty3)
      duty3 := dut
      if duty3 < 1
        duty3 := 1
      if duty3 > 15
       duty3 := 15
      divisions3 := divs
      if divisions3 < 0
        divisions3 := 0
      if divisions3 > 6
        divisions3 := 0
      table_adr3 := @chan3
    4:
      cognew(@InstSine, @duty4)
      duty4 := dut
      if duty4 < 1
        duty4 := 1
      if duty4 > 15
       duty4 := 15
      divisions4 := divs
      if divisions4 < 0
        divisions4 := 0
      if divisions4 > 6
        divisions4 := 0
      table_adr4 := @chan4

PUB NoiseWave(channel)
{{
                                            **********************************
--------------------------------------------*       Noise Instrument:        *------------------------------------------------------
                                            **********************************
                                            
Function:     This is a simple instrument that fills the wave channel with random values. The only argument needed is which
              one of the four channels you want loaded with noise

Timing:       It takes about 21,120 clocks to load a channel with noise.
              On 100 Mhz, this would be 211 microseconds
}}
  index := 0
  case channel
    1:
      repeat 128
        chan1[index] := ?rand
        index++  
    2:
      repeat 128
        chan2[index] := ?rand
        index++ 
    3:
      repeat 128
        chan3[index] := ?rand
        index++ 
    4:  
      repeat 128
        chan4[index] := ?rand
        index++

PUB AddNoise(channel, ammount, magnitude)
{{
                                            **********************************
--------------------------------------------*    Make Wave Table Noisier:    *------------------------------------------------------
                                            **********************************
                                            
Function:     Add some noise to a wave table. Knowing that there are 128 samples per wave table, the 'ammount' value affects how
              many potential samples will deviate (1-128). The magnitude is how much that sample level (voltage) will deviate,
              from where it's currently at (1-$FFFFFFFF). 
}}
  
  index := 0
  case channel
    1:
      repeat 128
        rchoice := ?rand & $0000FFFF  'Get random value from 0-$FFFF
        rchoice /= $1FF
        if rchoice < ammount    'If we want to add noise to this voltage then
          voltage := chan1[index]    'get the voltage
          if voltage < 0
            chan1[index] := voltage - (((?rand & $0FFFFFFF) // magnitude) * 8)
          else
            chan1[index] := voltage + (((?rand & $0FFFFFFF) // magnitude) * 8)
        index++  
    2:
      repeat 128
        rchoice := ?rand & $0000FFFF  'Get random value from 0-$FFFF
        rchoice /= $1FF
        if rchoice < ammount    'If we want to add noise to this voltage then
          voltage := chan2[index]    'get the voltage
          if voltage < 0
            chan2[index] := voltage - (((?rand & $0FFFFFFF) // magnitude) * 8)
          else
            chan2[index] := voltage + (((?rand & $0FFFFFFF) // magnitude) * 8)
        index++ 
    3:
      repeat 128
        rchoice := ?rand & $0000FFFF  'Get random value from 0-$FFFF
        rchoice /= $1FF
        if rchoice < ammount    'If we want to add noise to this voltage then
          voltage := chan3[index]    'get the voltage
          if voltage < 0
            chan3[index] := voltage - (((?rand & $0FFFFFFF) // magnitude) * 8)
          else
            chan3[index] := voltage + (((?rand & $0FFFFFFF) // magnitude) * 8)
        index++ 
    4:  
      repeat 128
        rchoice := ?rand & $0000FFFF  'Get random value from 0-$FFFF
        rchoice /= $1FF
        if rchoice < ammount    'If we want to add noise to this voltage then
          voltage := chan4[index]    'get the voltage
          if voltage < 0
            chan4[index] := voltage - (((?rand & $0FFFFFFF) // magnitude) * 8)
          else
            chan4[index] := voltage + (((?rand & $0FFFFFFF) // magnitude) * 8)
        index++ 
                    
DAT

              org       0
{{
                                            **********************************
--------------------------------------------*     PulseWave Instrument:      *------------------------------------------------------
                                            **********************************
                                            
Function:     This is a pulsewave instrument. It takes two duty cycle arguments and a divisional argument.
Duty Cycle:   0-16: The duty cycle value is a value from 0-16, but 1-15 would make the most sense audibly. Values outside of this
              range would be considered stupid
Divisions:    0-6: There are 128 sample values per wave table. Best audio quality would be to set divisions at 0. However, if you
              set the divisions to '1', it would divide this wave into 2 64 sample wave tables. The quality is half (well, we
              know this doesn't apply to a square wave), but the pitch goes up an octave (good for range). This also makes
              duty cycles that aren't multiples of two stupid. If you do division of '2', there are 4 waves, extra octave,
              more stupid duty cycles, less quality, etc... 6 is the highest value this can go, otherwise you're being stupid

Defaults:     If you pick a Duty Cycle out of range (0-16), a default of '8' will be selected, for 'half' duty. If you pick
              a Division value that is out of range (0-6), then a default of '0' will be selected (no divisions).

Timing:       It takes about 7,800 cycles to load a cog.
              Depending on divisions, this can take a total of 12,182 - 15,206 cycles to run (4,288 to 7,312 cog)
              On 80 Mhz, this is 152 - 190 microseconds
              On 100 Mhz, this is 121 - 152 microseconds

}}
              'Get Argument address
InstPulse     mov       d1, par
              mov       div, par
              mov       table, par
              'Calculate offsets
              add       div, #4
              add       table, #8
              'De-reference
              rdlong    d1, d1
              rdlong    div, div
              rdlong    table, table 
                                                 'divisions
              'Calculate Duties                  0  1   2   3   4   5
              sub       d2, d1       '16 - duty (for the other duty)
              shl       d1, #3                  '64  64  64  64  64  64
              shl       d2, #3                  '64  64  64  64  64  64

              'Adjust Duties based on divisions
              shr       d1, div                 '64  32  16  8   4   2
              shr       d2, div                 '64  32  16  8   4   2

              'Adjust Div as proper multiples of 2 looping
              mov       temp, #1                '1   1   1   1   1   1
              shl       temp, div               '1   2   4   8   16  32
              mov       div, temp               '1   2   4   8   16  32

        :Start
                        'Re-Init Duties
                        mov     d1_cnt, d1
                        mov     d2_cnt, d2
                        cmp     div, #0 wz
              if_z      jmp     #:End
                        
        :Duty1          cmp     d1_cnt, #0 wz
                        if_z    jmp    #:Duty2
                        wrlong  high, table
                        add     table, #4
                        sub     d1_cnt, #1
                        jmp     #:Duty1
        :Duty2          cmp     d2_cnt, #0 wz
                        if_z    jmp    #:Set
                        wrlong  low, table
                        add     table, #4
                        sub     d2_cnt, #1
                        jmp     #:Duty2

:Set          
              sub       div, #1
              jmp       #:Start

:End          cogid     cid
              cogstop   cid
'Values
temp     long  8
high     long  $FFFFFFFF
low      long  0
d2       long  16

d1       res 1
d1_cnt   res 1
d2_cnt   res 1
div      res 1
table    res 1

cid      res 1


DAT
              org       0
{{
                                            **********************************
--------------------------------------------*      Triangle Instrument:      *------------------------------------------------------
                                            **********************************
                                            
Function:     This is a Triangle/Saw Wave instrument. It takes two duty cycle arguments and a divisional argument.
Duty Cycle:   0-16: The duty cycle value is a value from 0-16, but 1-15 would make the most sense audibly. Values outside of this
              range would be considered stupid
Divisions:    0-6: There are 128 sample values per wave table. Best audio quality would be to set divisions at 0. However, if you
              set the divisions to '1', it would divide this wave into 2 64 sample wave tables. The quality is half, but the
              pitch goes up an octave (good for range). This also makes duty cycles that aren't multiples of two stupid.
              If you do division of '2', there are 4 waves, extra octave, more stupid duty cycles, less quality, etc...
              6 is the highest value this can go, otherwise you're being stupid

Defaults:     If you pick a Duty Cycle out of range (0-16), a default of '8' will be selected, for 'half' duty. If you pick
              a Division value that is out of range (0-6), then a default of '0' will be selected (no divisions).

Timing:       It takes about 7,800 cycles to load a cog.
              Depending on divisions, this can take a total of 12,246 - 16,278 cycles to run (4,370 to 8,384 cog)
              On 80 Mhz, this is 153 - 203 microseconds
              On 100 Mhz, this is 122 - 163 microseconds                             
}}
              'Get Argument address
InstTriangle  mov       t_d1, par
              mov       t_div, par
              mov       t_table, par
              'Calculate offsets
              add       t_div, #4
              add       t_table, #8
              'De-reference
              rdlong    t_d1, t_d1
              rdlong    t_div, t_div
              rdlong    t_table, t_table 

              'Calculate Step Scale based on Duty cycles
              sub       t_d2, t_d1               '16 - duty (for the other duty) 

              mov       t_step_val_1, #t_stepval0       'get first step value from lookup (get address of)
              add       t_step_val_1, t_d1              'Adjust offset              
              movs      t_dref1, t_step_val_1
              movd      t_adj1, t_step_val_1             

              mov       t_step_val_2, #t_stepval0       'get first step value from lookup
              add       t_step_val_2, t_d2              'Adjust offset              
              movs      t_dref2, t_step_val_2
              movd      t_adj2, t_step_val_2
                                                 'divisions
              'Calculate Duties                  0  1   2   3   4   5
              shl       t_d1, #3                  '64  64  64  64  64  64
              shl       t_d2, #3                  '64  64  64  64  64  64

              'Adjust Duties based on divisions
              shr       t_d1, t_div                 '64  32  16  8   4   2
              shr       t_d2, t_div                 '64  32  16  8   4   2
       t_adj1 shl       t_step_val_1, t_div
              cmp       t_d1, #32  wz               'if half duty cycle
        if_z  jmp       #skip_adjust2                'skip the 2nd shift, because same location is being refered to (don't shift again)
       t_adj2 shl       t_step_val_2, t_div
                                
       
              'Adjust Div as proper multiples of 2 looping
skip_adjust2  mov       t_temp, #1                  '1   1   1   1   1   1
              shl       t_temp, t_div               '1   2   4   8   16  32
              mov       t_div, t_temp               '1   2   4   8   16  32

        t_Start
                        'Re-Init Duties
                        mov     t_d1_cnt, t_d1
                        mov     t_d2_cnt, t_d2
                        mov     t_step_num, #0
                        cmp     t_div, #0 wz
              if_z      jmp     #t_End
                        
        t_Duty1         cmp     t_d1_cnt, #0 wz
                        if_z    jmp    #t_Duty2
                        wrlong  t_step_num, t_table
        t_dref1         add     t_step_num, t_step_val_1
                        add     t_table, #4
                        sub     t_d1_cnt, #1
                        jmp     #t_Duty1
        t_Duty2         cmp     t_d2_cnt, #0 wz
                        if_z    jmp    #t_Set
                        wrlong  t_step_num, t_table
        t_dref2         sub     t_step_num, t_step_val_2
                        add     t_table, #4
                        sub     t_d2_cnt, #1
                        jmp     #t_Duty2

t_Set          
              sub       t_div, #1
              jmp       #t_Start

t_End          cogid     t_cid
              cogstop   t_cid
'Values
t_temp     long  8
t_d2       long  16
t_step_num long  0
' Pre-computed Duty Cycle Scale Table
t_stepval0    long $FFFFFFFF
t_stepval1    long $1FFFFFFF
t_stepval2    long $FFFFFFF
t_stepval3    long $AAAAAA9
t_stepval4    long $7FFFFFF
t_stepval5    long $6666665
t_stepval6    long $5555554
t_stepval7    long $4924923
t_stepval8    long $3FFFFFF
t_stepval9    long $38E38E2
t_stepval10   long $3333332
t_stepval11   long $2E8BA2D
t_stepval12   long $2AAAAA9
t_stepval13   long $2762761
t_stepval14   long $2492491
t_stepval15   long $2222221
t_stepval16   long $1FFFFFF

t_step_val_1 res 1
t_step_val_2 res 1
t_d1       res 1
t_d1_cnt   res 1
t_d2_cnt   res 1
t_div      res 1
t_table    res 1

t_cid      res 1

DAT

              org       0
{{
                                            **********************************
--------------------------------------------*     SineWave Instrument:      *------------------------------------------------------
                                            **********************************
                                            
Function:     This is a sinewave instrument. It takes two duty cycle arguments and a divisional argument.
Duty Cycle:   0-16: The duty cycle value is a value from 0-16, but 1-15 would make the most sense audibly. Values outside of this
              range would be considered stupid
Divisions:    0-6: There are 128 sample values per wave table. Best audio quality would be to set divisions at 0. However, if you
              set the divisions to '1', it would divide this wave into 2 64 sample wave tables. The quality is half, but the pitch
              goes up an octave (good for range). If you do division of '2', there are 4 waves, extra octave, less quality, etc...
              6 is the highest value this can go, otherwise you're being stupid

Defaults:     If you pick a Duty Cycle out of range (1-15), a default of '1' or '15' will be selected. If you pick
              a Division value that is out of range (0-6), then a default of '0' will be selected (no divisions).

Timing:       It takes about 7,800 cycles to load a cog.
              Depending on divisions, this can take a total of 12,322 - 15490 cycles to run (3,732? to 7,600? cog)
              On 100 Mhz, this is 123? - 155? microseconds

              Sine Table ROM Address Range for Quadrant 1. $E000 - $F001

}}
              'Get Argument address
InstSine      mov       s_d1, par
              mov       s_div, par
              mov       s_table, par
              'Calculate offsets
              add       s_div, #4
              add       s_table, #8
              'De-reference
              rdlong    s_d1, s_d1
              rdlong    s_div, s_div
              rdlong    s_table, s_table 

              'Calculate Stepping
              cmp       s_d1, #15 wz
        if_z  mov       s_sinstep, #$44
        if_z  mov       s_sinstep2, s_400
              cmp       s_d1, #14 wz
        if_z  mov       s_sinstep, #$49
        if_z  mov       s_sinstep2, s_200
              cmp       s_d1, #13 wz
        if_z  mov       s_sinstep, #$4e
        if_z  mov       s_sinstep2, #$155
              cmp       s_d1, #12 wz
        if_z  mov       s_sinstep, #$55
        if_z  mov       s_sinstep2, #$100
              cmp       s_d1, #11 wz
        if_z  mov       s_sinstep, #$5d
        if_z  mov       s_sinstep2, #$cc
              cmp       s_d1, #10 wz
        if_z  mov       s_sinstep, #$66
        if_z  mov       s_sinstep2, #$aa
              cmp       s_d1, #9 wz
        if_z  mov       s_sinstep, #$71
        if_z  mov       s_sinstep2, #$92
              cmp       s_d1, #8 wz
        if_z  mov       s_sinstep, #$80
        if_z  mov       s_sinstep2, #$80
              cmp       s_d1, #7 wz
        if_z  mov       s_sinstep, #$92
        if_z  mov       s_sinstep2, #$71
              cmp       s_d1, #6 wz
        if_z  mov       s_sinstep, #$aa
        if_z  mov       s_sinstep2, #$66
              cmp       s_d1, #5 wz
        if_z  mov       s_sinstep, #$cc
        if_z  mov       s_sinstep2, #$5d
              cmp       s_d1, #4 wz
        if_z  mov       s_sinstep, #$100
        if_z  mov       s_sinstep2, #$55
              cmp       s_d1, #3 wz
        if_z  mov       s_sinstep, #$155
        if_z  mov       s_sinstep2, #$4e
              cmp       s_d1, #2 wz
        if_z  mov       s_sinstep, s_200
        if_z  mov       s_sinstep2, #$49
              cmp       s_d1, #1 wz
        if_z  mov       s_sinstep, s_400
        if_z  mov       s_sinstep2, #$44                                                                                                        

              'Adjust Stepping based on divisions
              shl       s_sinstep, s_div
              shl       s_sinstep2, s_div
                                            
              'Calculate Duties                
              sub       s_d2, s_d1       '16 - duty (for the other duty)
              shl       s_d1, #2                 
              shl       s_d2, #2               

              'Adjust Duties based on divisions
              shr       s_d1, s_div                 
              shr       s_d2, s_div               

              'Adjust Div as proper multiples of 2 looping
              mov       s_temp, #1                
              shl       s_temp, s_div               
              mov       s_div, s_temp

              'Setup SineStepping               

        :s_Start
                        'Re-Init Duties
                        mov     s_d1_cnt, s_d1
                        mov     s_d2_cnt, s_d1
                        mov     s_d3_cnt, s_d2
                        mov     s_d4_cnt, s_d2
                        cmp     s_div, #0 wz
              if_z      jmp     #:s_End
                        
        :s_Quadrant1    cmp     s_d1_cnt, #0 wz
                        if_z    jmp    #:s_Quadrant2

                        rdlong  s_sinsamp, s_sinaddr
                        shr     s_sinsamp, #1
                        add     s_sinsamp, s_middle
                        wrlong  s_sinsamp, s_table
                        add     s_sinaddr, s_sinstep

                        add     s_table, #4
                        sub     s_d1_cnt, #1
                        jmp     #:s_Quadrant1

        :s_Quadrant2    cmp     s_d2_cnt, #0 wz
                        if_z    jmp    #:s_Quadrant3

                        sub     s_sinaddr, s_sinstep
                        rdlong  s_sinsamp, s_sinaddr
                        shr     s_sinsamp, #1
                        add     s_sinsamp, s_middle
                        wrlong  s_sinsamp, s_table
                        
                        add     s_table, #4
                        sub     s_d2_cnt, #1
                        jmp     #:s_Quadrant2

        :s_Quadrant3    cmp     s_d3_cnt, #0 wz
                        if_z    jmp    #:s_Quadrant4

                        rdlong  s_sinsamp, s_sinaddr
                        shr     s_sinsamp, #1
                        mov     s_temp, s_middle
                        sub     s_temp, s_sinsamp
                        mov     s_sinsamp, s_temp
                        wrlong  s_sinsamp, s_table
                        add     s_sinaddr, s_sinstep2
                        
                        add     s_table, #4
                        sub     s_d3_cnt, #1
                        jmp     #:s_Quadrant3

        :s_Quadrant4    cmp     s_d4_cnt, #0 wz
                        if_z    jmp    #:s_Set

                        sub     s_sinaddr, s_sinstep2
                        rdlong  s_sinsamp, s_sinaddr
                        shr     s_sinsamp, #1
                        mov     s_temp, s_middle
                        sub     s_temp, s_sinsamp
                        mov     s_sinsamp, s_temp
                        wrlong  s_sinsamp, s_table
                        
                        add     s_table, #4
                        sub     s_d4_cnt, #1
                        jmp     #:s_Quadrant4                        

:s_Set          
              sub       s_div, #1
              jmp       #:s_Start

:s_End        cogid     s_cid
              cogstop   s_cid
'Values
s_temp     long  8
s_d2       long  16
s_sinaddr  long  $E000
s_sinstep  long  $80
s_sinstep2 long  $80
s_middle   long  $80000000
s_200      long  $200
s_400      long  $400

s_d1       res 1
s_d1_cnt   res 1
s_d2_cnt   res 1
s_d3_cnt   res 1
s_d4_cnt   res 1
s_div      res 1
s_table    res 1

s_sinsamp  res 1

s_cid      res 1


DAT

              org       0
{{
                                            **********************************
--------------------------------------------*          Mixer Engine:         *------------------------------------------------------
                                            **********************************
                                            
Function:     This engine will take the 4 samples to mix (as an address of each), mix them, add effects, then put the output on
              a shared address for consumption by PCM engine.
How it works:
Notes:        -Continiously runs (without being called); expect the output address to hold a semi up to date mix of values in the
              channel addresses in real time.
                        
}}

Mixer         mov       mx_adr1, par           
              mov       mx_adr2, par
              mov       mx_adr3, par
              mov       mx_adr4, par
              mov       mx_out_adr, par
              mov       qual_adr, par
              mov       m_garb_adr, par
              mov       m_not_adr, par
              mov       vol1_adr, par              
              mov       vol2_adr, par
              mov       vol3_adr, par
              mov       vol4_adr, par
              ''indexes them
              add       mx_adr1, #84
              add       mx_adr2, #88
              add       mx_adr3, #92
              add       mx_adr4, #96
              add       mx_out_adr, #100
              add       qual_adr, #32
              add       m_garb_adr, #40
              add       m_not_adr, #44
              add       vol1_adr, #16
              add       vol2_adr, #20
              add       vol3_adr, #24
              add       vol4_adr, #28
              
              ''put values (also addresses) at the addresses in local workspace
:MXStart      rdlong    mx_val1, mx_adr1
              rdlong    mx_val2, mx_adr2
              rdlong    mx_val3, mx_adr3
              rdlong    mx_val4, mx_adr4
              ''put the values of the addresses of the addresses in the local workspace (double dereferencing)
              rdlong    mx_val1, mx_val1
              rdlong    mx_val2, mx_val2
              rdlong    mx_val3, mx_val3
              rdlong    mx_val4, mx_val4                             

              ''Set Volumes and Mix
              'divide them all by 4
              shr       mx_val1, #2
              shr       mx_val2, #2
              shr       mx_val3, #2
              shr       mx_val4, #2
              'read volumes
              rdlong    vol1, vol1_adr
              rdlong    vol2, vol2_adr
              rdlong    vol3, vol3_adr
              rdlong    vol4, vol4_adr
              'set/apply volumes (done with shifting, not the best method, but computationally quick)
              shr       mx_val1, vol1
              shr       mx_val2, vol2
              shr       mx_val3, vol3
              shr       mx_val4, vol4
              'add them back together
              add       mx_val1, mx_val2
              add       mx_val1, mx_val3
              add       mx_val1, mx_val4

              'read quality
              rdlong    qual, qual_adr
              'apply quality
              mov       qualmask, F_mask
              shl       qualmask, qual
              and       mx_val1, qualmask

              'read garble
              rdlong    m_garb, m_garb_adr
              'apply garble
              mov       garbmask, F_mask
              shr       garbmask, m_garb
              and       mx_val1, garbmask
              sub       m_garb, #2 wc
        if_nc shl       mx_val1, m_garb

              'read or mask
              rdlong    m_not, m_not_adr
              'apply mask
              shl       m_not, #24
              or        mx_val1, m_not

              'write result to output address
              wrlong    mx_val1, mx_out_adr

              jmp       #:MXStart                            
              

F_Mask        long $FFFFFFFF

'Pointers
mx_adr1       res 1
mx_adr2       res 1
mx_adr3       res 1
mx_adr4       res 1
mx_out_adr    res 1
qual_adr      res 1 
m_garb_adr    res 1
m_not_adr     res 1
vol1_adr      res 1
vol2_adr      res 1
vol3_adr      res 1
vol4_adr      res 1

'Values
mx_val1       res 1
mx_val2       res 1
mx_val3       res 1
mx_val4       res 1
qual          res 1
m_garb        res 1
garbmask      res 1
m_not         res 1
notmask       res 1
vol1          res 1
vol2          res 1
vol3          res 1
vol4          res 1
qualmask      res 1

''
''************************************************************************************************************************************

              org       0
{{
                                            **********************************
--------------------------------------------*          PCM Engine:           *------------------------------------------------------
                                            **********************************
                                            
Function:     This engine keeps track of where the signal level of each channel should be in time. It first goes through a check
              through each channel to decide the level, while placing those levels in the mixer data. The engine next takes the
              mixer output and throws it on the PWM engine (a part of this engine)
How it works: For any wave you want to play, you must set done flags to 0 from SPIN.
Notes:       

        ------------------------------                                                         
     ┳─→| Fetch duration & done_flag |                                                         
     │  | values from main memory    |                                                         
     │  ---------┳--------------------                                                         
     │           │                                                                             
     │           ↓                                                                             
     │  ┳─────────────────────┳   yes   --------                                               
     │  │ Is channel 1 done?  ┣────────→| Skip ┣─────────────────────────────────────────┳     
     │  ┻────────┳────────────┻         --------                                         │     
     │           │                                                                       │     
     │           ↓no                                                                     │     
     │  ------------------------------                                                   │     
     │  | Decrement a tic of holding |                                                   │     
     │  | the PWM at its current val |                                                   │     
     │  ---------┳--------------------                                                   │     
     │           │                                                                       │     
     │           ↓                                                                       │                                             
     │  ┳─────────────────────┳       ------------------------------                     │     
     │  │ are the tics empty/ │ yes   | go to next PCM value for   |                     │     
     │  │ done/=0?            ┣──────→| PWM output                 |                     │     
     │  ┻────────┳────────────┻       ------------┳-----------------                     │     
     │           │                                │                                      │     
     │           ↓no                              ↓                                      │     
     │  ┳─────────────────────┳       ------------------------------                     │     
     │  │ is it at the end of │       | reset tic count to initial |                     │                     
     │  │ the wave (index ==  │←──────┫ parameter                  |                     │     
     │  │ 128)?               │       ------------------------------                     │     
     │  ┻──┳────────────┳─────┻                                                          │     
     │     │            ↓yes                                                             │     
     │     │         ------------------------------                                      │
     │     │         | Check for new tic value;   |                                      │
     │     │         | change in frequency        |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │         ------------------------------                                      │
     │     │         | go back to first PCM value |                                      │
     │     │         | for the wave (reset index) |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │         ------------------------------                                      │
     │     │         | decrement loop count (how  |                                      │
     │     │         | many times to play that    |                                      │
     │     │         | shape). Also update main   |                                      │
     │     │         | memory with this value.    |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │          ┳─────────────────────┳          ------------------------------    │
     │     │          │ is loop count down  │   yes    | set channel 1 (flag) to    |    │     
     │     │          │ to 0?               ┣─────────→| done.                      |    │     
     │     │          ┻┳────────────────────┻          ----┳-------------------------    │     
     │     │           │no                                 │                             │     
     │     ↓           ↓                                   │                             │     
     │    ------------------------                         │                             │     
     │    | Do same routine for  |\                        │                             │     
     │    | channel 2, 3, and 4. | |\                      │                             │     
     │    ------------------------\| |←────────────────────┻                             │     
     │    \------------------------\ |←──────────────────────────────────────────────────┻     
     │     \-----------┳-------------|                                                         
     │                 │                                                                       
     │                 ↓                                                                       
     │     ------------------------------                                                      
     │     | Get mix and send it to PCM |                                                      
     ┻─────┫ engine (frqa)              |                                                                                          
           ------------------------------

CALL/RET unrolling was intentional for each of the 4 channels. Though CALL/RET could save some (marginal)
space, unrolling is better for performance. That and Propeller Assembly doesn't have a stack, so you can
only have one RET (exit point) in a CALL/RET routine without doing some weird RET-index hacking. Also,
not much space is saved rolling into CALL/RET here due to the large amount of parameters that would have
to be MOVed into place before each of the CALLs
                        
}}

          
              'get un-indexed addresses
PCM           mov       chan1_tic_adr, par      'freq1
              mov       chan2_tic_adr, par      'freq2
              mov       chan3_tic_adr, par      'freq3
              mov       chan4_tic_adr, par      'freq4
              mov       chan1_dur_adr, par      'dur1
              mov       chan2_dur_adr, par      'dur2
              mov       chan3_dur_adr, par      'dur3
              mov       chan4_dur_adr, par      'dur4
              mov       p_mx_adr1, par          'mix address 1     
              mov       p_mx_adr2, par          'mix address 2
              mov       p_mx_adr3, par          'mix address 3
              mov       p_mx_adr4, par          'mix address 4
              mov       p_mx_out_adr, par       'mix output address
              mov       chan1_done_adr, par     'channel 1 done flag address
              mov       chan2_done_adr, par     'channel 2 done flag address
              mov       chan3_done_adr, par     'channel 3 done flag address
              mov       chan4_done_adr, par     'channel 4 done flag address
              mov       datastart, par          'data area
              mov       p_pin, par              'audiopin
              ''indexes them
              add       chan2_tic_adr, #4       'freq
              add       chan3_tic_adr, #8       'freq
              add       chan4_tic_adr, #12      'freq
              add       chan1_dur_adr, #48      'dur
              add       chan2_dur_adr, #52      'dur
              add       chan3_dur_adr, #56      'dur
              add       chan4_dur_adr, #60      'dur
              add       p_mx_adr1, #84          'mix
              add       p_mx_adr2, #88          'mix
              add       p_mx_adr3, #92          'mix
              add       p_mx_adr4, #96          'mix
              add       p_mx_out_adr, #100      'mix out
              add       chan1_done_adr, #104    'flag
              add       chan2_done_adr, #108    'flag
              add       chan3_done_adr, #112    'flag
              add       chan4_done_adr, #116    'flag
              add       datastart, #36          'data area
              add       p_pin, #120             'audio pin

              rdlong    p_pin, p_pin            'get pin number
              shl       pinmask, p_pin          'shift it acordingly
              or        dira, pinmask           'add it to mask

              or        CtrCfg, p_pin           'add pin number to ctra mask
              mov       ctra, CtrCfg            'single ended duty

              rdlong    datastart, datastart
              add       p_chanadr1, datastart 
              add       p_chanadr2, p_chanadr1
              add       p_chanadr3, p_chanadr1
              add       p_chanadr4, p_chanadr1               

              mov       mstart, datastart
              sub       mstart, #4
              add       m214, mstart
              add       m414, mstart
              add       m614, mstart
              add       m814, mstart
              add       m218, datastart
              add       m418, datastart
              add       m618, datastart
              add       m818, datastart

              'initialize tics
              rdlong    chan1_tic, chan1_tic_adr        '\
              rdlong    chan2_tic, chan2_tic_adr        ' \
              rdlong    chan3_tic, chan3_tic_adr        '  \
              rdlong    chan4_tic, chan4_tic_adr        '   update local frequency data with main memory

              'start blasting initial PCM's (since the will be initial values anyway)
              rdlong    p_temp, p_mx_out_adr            'get the current mix output into a temporary value
              mov       frqa, p_temp                    'put it on the PWM engine

              'initialize durs
:PStart       mov       delaycnt, CNT
              add       delaycnt, masterdelay
              rdlong    chan1_dur, chan1_dur_adr        '\
              rdlong    chan2_dur, chan2_dur_adr        ' \
              rdlong    chan3_dur, chan3_dur_adr        '  \
              rdlong    chan4_dur, chan4_dur_adr        '   update local channel duration with main memory

              'see if SPIN decided to re-initialize a channel
              rdlong    chan1_done, chan1_done_adr      '\
              rdlong    chan2_done, chan2_done_adr      ' \
              rdlong    chan3_done, chan3_done_adr      '  \
              rdlong    chan4_done, chan4_done_adr      '   update local flag data with main memory
          
''Channel 1 update routine  
              'Is channel 1 done?
:Chan1        mov       p_temp, #1              '\
              sub       p_temp, chan1_done  wz  ' \
        if_z  jmp       #:Chan2               '  Is channel 1 flag set (done/1)

              'Decrement a tic of holding the PWM at its current val
              sub       chan1_tic, #1  wz

              'Are the ticks empty/done/=0?
       if_nz  jmp       #:EndWave1            'if tics aren't done, skip getting next PCM and resetting tic

              'Go to the next PCM value for PWM output
              add       p_chanadr1, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr1, p_mx_adr1  'put address of the next PCM value on p_mx_adr1 line for mixer

              'Reset tick count to initial parameter
              rdlong    chan1_tic, chan1_tic_adr

              'Is it at the end of the wave (index == 128)?
:EndWave1     mov       p_temp, m214             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr1  wz   'if at end, zero flag will set
        if_nz jmp       #:Chan2                 'no need to update if not at end of index, proceed to next chan.      

              'check for new tick value; change in frequency       
              rdlong    chan1_tic, chan1_tic_adr

              'Go back to first PCM value for the wave (reset index)
              mov       p_chanadr1, datastart         'go back to first PCM value

              'Decrement loop count (how many times to play that shape). Also update main memory with this value
              sub       chan1_dur, #1            'decrement amount of times to play wave
              wrlong    chan1_dur, chan1_dur_adr 'make sure main memory has an updated copy too                                   

              'Is Loop Count down to 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan1_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan2                  '

              'set channel 1 (flag) to done
              mov       chan1_done, #1
              wrlong    chan1_done, chan1_done_adr 'update main memory as well                                                        


'Channel 2 update routine          
:Chan2        mov       p_temp, #1              '\
              sub       p_temp, chan2_done  wz  ' \
        if_z  jmp       #:Chan3               '  Is channel 2 flag set (done/1)

              sub       chan2_tic, #1  wz     'decrement a tic, make note of if it hit zero
        if_nz jmp       #:EndWave2            'if tics aren't done, skip getting next PCM and resetting tic

              'NextPCM
              add       p_chanadr2, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr2, p_mx_adr2  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan2_tic, chan2_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave2     mov       p_temp, m414             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr2  wz     'if at end, zero flag will set
        if_nz jmp       #:Chan3                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan2_tic, chan2_tic_adr        
'go back to first PCM value
              mov       p_chanadr2, m218         'go back to first PCM value
'decrement loop count
              sub       chan2_dur, #1            'decrement amount of times to play wave
              wrlong    chan2_dur, chan2_dur_adr 'make sure main memory has an updated copy too                                 
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan2_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan3                  '

'set chan1 to done
              mov       chan2_done, #1
              wrlong    chan2_done, chan2_done_adr 'update main memory as well                                                          

'Channel 3 update routine          
:Chan3        mov       p_temp, #1              '\
              sub       p_temp, chan3_done  wz  ' \
        if_z  jmp       #:Chan4               '  Is channel 2 flag set (done/1)

              sub       chan3_tic, #1  wz     'decrement a tic, make note of if it hit zero
       if_nz  jmp       #:EndWave3            'if tics aren't done, skip getting next PCM and resetting tic

              add       p_chanadr3, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr3, p_mx_adr3  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan3_tic, chan3_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave3     mov       p_temp, m614             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr3  wz     'if at end, zero flag will set
        if_nz jmp       #:Chan4                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan3_tic, chan3_tic_adr        
'go back to first PCM value
              mov       p_chanadr3, m418         'go back to first PCM value
'decrement loop count
              sub       chan3_dur, #1            'decrement amount of times to play wave
              wrlong    chan3_dur, chan3_dur_adr 'make sure main memory has an updated copy too                                  
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan3_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan4                  '

'set chan1 to done
              mov       chan3_done, #1
              wrlong    chan3_done, chan3_done_adr 'update main memory as well                                                      

'Channel 4 update routine          
:Chan4        mov       p_temp, #1              '\
              sub       p_temp, chan4_done  wz  ' \
        if_z  jmp       #:Send                '  Is channel 2 flag set (done/1)

              sub       chan4_tic, #1  wz     'decrement a tic, make note of if it hit zero
       if_nz  jmp       #:EndWave4            'if tics are done, Next PCM

              add       p_chanadr4, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr4, p_mx_adr4  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan4_tic, chan4_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave4     mov       p_temp, m814             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr4  wz     'if at end, zero flag will set
        if_nz jmp       #:Send                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan4_tic, chan4_tic_adr        
'go back to first PCM value
              mov       p_chanadr4, m618         'go back to first PCM value
'decrement loop count
              sub       chan4_dur, #1            'decrement amount of times to play wave
              wrlong    chan4_dur, chan4_dur_adr 'make sure main memory has an updated copy too                                  
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan4_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Send                  '

'set chan1 to done
              mov       chan4_done, #1
              wrlong    chan4_done, chan4_done_adr 'update main memory as well
              
:Send         rdlong    p_temp, p_mx_out_adr    'get value of mix out
              mov       frqa, p_temp            'put it on the PCM
              waitcnt   delaycnt, 0
              jmp       #:PStart



'Flags
'1 means done, 0 means still working
chan1_done      long 0
chan2_done      long 0
chan3_done      long 0
chan4_done      long 0
chan1_done_adr  long 0
chan2_done_adr  long 0
chan3_done_adr  long 0
chan4_done_adr  long 0

'PWM 'tics'
chan1_tic     long 0
chan2_tic     long 0
chan3_tic     long 0
chan4_tic     long 0
chan1_tic_adr long 0
chan2_tic_adr long 0
chan3_tic_adr long 0
chan4_tic_adr long 0

'loop counts
chan1_dur     long 0
chan2_dur     long 0
chan3_dur     long 0
chan4_dur     long 0
chan1_dur_adr long 0
chan2_dur_adr long 0
chan3_dur_adr long 0
chan4_dur_adr long 0

p_temp          long 0

p_mx_adr1       long 0
p_mx_adr2       long 0
p_mx_adr3       long 0
p_mx_adr4       long 0
p_mx_out_adr    long 0

p_mx_val1       long 0
p_mx_val2       long 0
p_mx_val3       long 0
p_mx_val4       long 0

p_pin         long 0
CtrCfg        long %0_00110_000_00000000_000000_000_000000  'single ended duty, pin 31 
pinmask       long $00000001                                'make pin 31 an output

'These are just masks higher than the 9-bit immediate values would allow. I know the names are arbitrary looking,
'they weren't arbitrary when I first created them, I swear. I may fix them when I'm finished with everything, I
'have just changed their values too much to what to do find and replace everytime.
m214          long $200
m218          long $200         
m414          long $400
m418          long $400
m614          long $600
m618          long $600
m814          long $800
m818          long $800
mstart        long 0

datastart     long 0
p_chanadr1    long 0                          'address of chan1 wave uncompressed
p_chanadr2    long $200                         'address of chan2 wave uncompressed
p_chanadr3    long $400                         'address of chan3 wave uncompressed
p_chanadr4    long $600                         'address of chan4 wave uncompressed

masterdelay   long 887          'max time it would take to process all channels
delaycnt      res 1

fit     220            '496 is highest


{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
