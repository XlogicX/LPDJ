{{
2022 Live Set
AUTHOR: XlogicX
Copyright (c) 2022 (MIT Terms of use; see end of file)

••••••••••••••••••••••••••••••••••••••••••••••••••••••  Description ••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
Program used for setlist used in 2022 'tour.' This includes a album release party for Nick Vivid 
and A New HOPE (Hackers On Planet Earth) in 2022.

Note thet LIB_NES is not in this repo, as it didn't have a free enough liscense at the time of 
writing. It is included in sources for the HYDRA platform.

There are things in here not used in my live set; I use many NES style SFX, but programmed in here
are far more SFX than actually used

}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_250_000

  NES1_RIGHT  = %00000001_00000000
  NES1_LEFT   = %00000010_00000000
  NES1_DOWN   = %00000100_00000000
  NES1_UP     = %00001000_00000000
  NES1_START  = %00010000_00000000
  NES1_SELECT = %00100000_00000000
  NES1_B      = %01000000_00000000
  NES1_A      = %10000000_00000000                                           

' LED Pins
  Blue = 0
  Green = 1
  Red = 2

#0 ' WAT? 


obj
  pcm : "LPDJ"
  game  : "LIB_NES"              'instantiate a nintendo phearness  
  serial        : "FullDuplexSerial" 
  
var

' Main variables/init
long    delta
long    bpm
long    note

' Used in Noise Jam Program (and in main init)
long    pulselvl
long    noiselvl
 
' BassOS Program Selection process (and SFX selection)
long    program_index

' 8-bit Player Functions
byte    idx

' PulsePlayer (including Sweep) Variables
byte    volumes[110]    ' Can expand these if more datapoints are needed
byte    dutys[110]
' Player
byte    p1volumes[110]
byte    p1dutys[110]
byte    p2volumes[110]
byte    p2dutys[110]
byte    pcount


'SFX Tracker
byte    sounds

' Noise Jam variables
long    pitch
long    inst

' Death to MegaMan routine
byte    state

' Effects Demo
byte    pulses[100]
byte    pulses2[100]
byte    triangles[100]
byte    high
byte    low
long    speed
byte    mask
byte    distort

' Tapping
long    tap_a
long    tap_b

pub main

game.start
pcm.start (15, 100)  '27 on Bass Guitar, 15 on portable unit
' too slow: 40
' too fast: 48
bpm := 46
delta := clkfreq/((bpm*4)/60)

' Init?
pcm.SineWave(1, 8, 1)
pcm.TriangleWave(2, 2, 0)
pcm.PulseWave(3, 8, 2)
pcm.NoiseWave(4)
noiselvl := 0
pulselvl :=8
note := 0

' Make LED pins outputs
dira[Red] := 1
dira[Green] := 1
dira[Blue] := 1

Entry

PUB Entry
  ' Main Menu, SELECT should return to this menu from any routine (as a sane convention)
  ' UP and DOWN allows to pick different programs
  ' RIGHT and LEFT skips 10 programs at a time
  ' A Enters the Program

  ' Init Program Index
  program_index := 0
  sounds := 3           ' really an index of total programs (start at 0 count), not 'sounds.'

  ' Show that we made it into the main menu
  Flash(Red, 3_000_000)
  
  repeat
    if game.button(NES1_START)
      ProgramPicker(program_index)
      Debounce
    if game.button(NES1_UP)
       if program_index == sounds
          program_index := 0
       else
          program_index++
      Flash(Blue, 3_000_000)
      Debounce
    if game.button(NES1_DOWN)
      if program_index == 0
        program_index := sounds
      else
        program_index--
      Flash(Blue, 3_000_000)
      Debounce

PUB ProgramPicker(Index)
  serial.Start(31, 30, %0000, 9_600)
  ' User has made selection of Program to run, this routine takes that selection (an integer)
  ' and runs the program accociated with it (case/switch)
  case Index
    0:
      NoiseJam
    1:
      DeathtoMegaManRythm
    2:
      BinaryCodedDecible
    3:
      program_index := 0
      SFX
    4:
      Tapping

PUB Tapping
  serial.Dec(clkfreq)
  serial.Tx($0D)
  repeat
    if game.button(NES1_DOWN)
      delta := TAP_IN
      DeathtoMegaManRythm
    if game.button(NES1_SELECT)
      Return



PUB TAP_IN
  repeat until (game.button(NES1_A))
  tap_a := cnt 
  repeat until (game.button(NES1_A) == False)
  TAP_IN_B
  repeat 3
    TAP_IN_A
    TAP_IN_B
  delta := delta/7
  return delta
  
PUB TAP_IN_B
  repeat until (game.button(NES1_B))
  tap_b := cnt
  delta := delta + tap_b - tap_a
  repeat until (game.button(NES1_B) == False)

PUB TAP_IN_A
  repeat until (game.button(NES1_A))
  tap_a := cnt
  delta := delta + tap_a - tap_b
  repeat until (game.button(NES1_A) == False)


PUB BinaryCodedDecible
' 6144 = D
  ' Init Program Index
  state := 1
  program_index := 0
  sounds := 20

  repeat
    if game.button(NES1_A)
      if state == 0
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 1
      BCDPicker(program_index)
    if game.button(NES1_B)
      if state == 1
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 0   
      BCDPicker(program_index) 
    if game.button(NES1_SELECT)
      Return
PUB BCDPicker(Index)
  pcm.SineWave(1, 8, 1)
  pcm.PulseWave(2, 8, 1)  
  case Index
    0:
      pcm.Playnote(1, 24, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 12, 3, 0, 0, 0, 2)
    1:
      pcm.Playnote(1, 28, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 14, 3, 0, 0, 0, 2)
    2:
      pcm.Playnote(1, 36, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 18, 3, 0, 0, 0, 2)
    3:
      pcm.Playnote(1, 16, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 8, 3, 0, 0, 0, 2)
    4:
      BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadygunsamples, @tmntrocksteadygunvolumes, 2_000_000)
    5:
      pcm.Playnote(1, 12, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 24, 3, 0, 0, 0, 2)
    6:
      pcm.Playnote(1, 14, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 28, 3, 0, 0, 0, 2)
    7:
      pcm.Playnote(1, 18, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 36, 3, 0, 0, 0, 2)
    8:
      pcm.Playnote(1, 8, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 16, 3, 0, 0, 0, 2)
    9:
      BitPlayer($08, @marioexplosionpitches, @marioexplosiondvs, 0, 0, 0, 0, 0, 0, 1_500_000)  
    10:
      pcm.Playnote(1, 24, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 12, 3, 0, 0, 0, 2)
    11:
      pcm.Playnote(1, 28, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 14, 3, 0, 0, 0, 2)
    12:
      pcm.Playnote(1, 36, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 18, 3, 0, 0, 0, 2)
    13:
      pcm.Playnote(1, 16, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 8, 3, 0, 0, 0, 2)
    14:
      BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadygunsamples, @tmntrocksteadygunvolumes, 2_000_000)
    15:
      pcm.Playnote(1, 12, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 24, 3, 0, 0, 0, 2)
    16:
      pcm.Playnote(1, 14, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 28, 3, 0, 0, 0, 2)
    17:
      pcm.Playnote(1, 18, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 36, 3, 0, 0, 0, 2)
    18:
      pcm.Playnote(1, 8, 2, 0, 0, 0, 2)    '
      pcm.Playnote(2, 16, 3, 0, 0, 0, 2)
    19:
      BitPlayer($08, @marioexplosionpitches, @marioexplosiondvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    20:
      NoiseJam
      
PUB DeathtoMegaManRythm
  ' Init Program Index
  state := 1
  program_index := 0
  sounds := 6

  repeat
    if game.button(NES1_A)
      if state == 0
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 1
      MegaPickerRythm(program_index)
    if game.button(NES1_B)
      if state == 1
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 0   
      MegaPickerRythm(program_index) 
    if game.button(NES1_SELECT)
      MegaDeath
      Reboot

PUB MegaPickerRythm(Index)
  ' User has made selection of sound to run, this routine takes that selection (an integer)
  ' and runs the sound accociated with it (case/switch)
  case Index
    0:
      BitPlayer($02, 0, 0, 0, 0, @megaelecmanpitches, @megaelecmanvolumes, 0, 0, delta/16)
    1:
      BitPlayer($08, @megalazerpitches, @megalazerdvs, 0, 0, 0, 0, 0, 0, delta/23)
    2:
      repeat 8
        BitPlayer($03, 0, 0, 0, 0, @megaelecbrickpitches, @megaelecbrickvolumes, @megaelecbricksamples, @megaelecbricknvolumes, delta/48)
    3:
      'BitPlayer($0A, @megabomberpulsepitches, @megabomberdvs, 0, 0, @megabombertripitches, @megabombervolumes, 0, 0, delta/7)
      BitPlayer($0B, @megaattackedpulsepitches, @megaattackedpulsevolumes, 0, 0, @megattackedtripitches, @megattackedtrivolumes, @megaattackednoises, @megaattackednoisesvolumes, delta/17)
    4:
      BitPlayer($02, 0, 0, 0, 0, @megaelecmanpitches, @megaelecmanvolumes, 0, 0, delta/16)
    5:
      'BitPlayer($0B, @megaattackedpulsepitches, @megaattackedpulsevolumes, 0, 0, @megattackedtripitches, @megattackedtrivolumes, @megaattackednoises, @megaattackednoisesvolumes, delta/17)
      distort := 3   ' abusing var as 'flag' for basic Return from Distorter
      'Distorter($0B, @megaattackedpulsepitches, @megaattackedpulsevolumes, 0, 0, @megattackedtripitches, @megattackedtrivolumes, @megaattackednoises, @megaattackednoisesvolumes, delta/17)
      Distorter($0A, @megabomberpulsepitches, @megabomberdvs, 0, 0, @megabombertripitches, @megabombervolumes, 0, 0, delta/7)
      distort := 0
      Debounce
    6:
      BitPlayer($02, 0, 0, 0, 0, @megaelecmanpitches, @megaelecmanvolumes, 0, 0, delta/16)




PUB DeathtoMegaMan
  ' Init Program Index
  state := 1
  program_index := 0
  sounds := 5

  repeat
    if game.button(NES1_A)
      if state == 0
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 1
      MegaPicker(program_index)
    if game.button(NES1_B)
      if state == 1
        if program_index == sounds
          program_index := 0
        else
          program_index++
      state := 0   
      MegaPicker(program_index) 
    if game.button(NES1_SELECT)
      MegaDeath
      Reboot

PUB MegaPicker(Index)
  ' User has made selection of sound to run, this routine takes that selection (an integer)
  ' and runs the sound accociated with it (case/switch)
  case Index
    0:
      MegaElecMan
    1:
      MegaLazer
    2:
      MegaAttacked
    3:
      MegaBomber
    4:
      MegaElecMan
    5:
      MegaElecBrick

PUB Distorter(chans, dpulses, dvs1, dpulses2, dvs2, dtriangles, tvs, samples, nvs, init_speed)

  ' Get repetitions / amount of pitches to play
  idx := 0
  if (chans & %1000)
    repeat while (byte[dpulses][idx] > 0)
      idx++
  elseif (chans & %0100)
    repeat while (byte[dpulses2][idx] > 0)
      idx++ 
  elseif (chans & %0010)
    repeat while (byte[dtriangles][idx] > 0)
      idx++
  else
    repeat while (byte[samples][idx] > 0)
      idx++
  pcount := idx
  
  idx := 0
  low := byte[dpulses][0]     ' first value is lowest so far
  if byte[dpulses2][0] < low
    low := byte[dpulses2][0]
  if byte[dtriangles][0] < low     ' if first tri val is lower, that's lowest so far
    low := byte[dtriangles][0]

  high := byte[dpulses][0]     ' first value is highest so far
  if byte[dpulses2][0] > high
    high := byte[dpulses2][0]
  if byte[dtriangles][0] > high     ' if first tri val is higher, that's highest so far
    high := byte[dtriangles][0]

  repeat pcount
    ' building copy of sfx
    pulses[idx] := byte[dpulses][idx]
    pulses2[idx] := byte[dpulses2][idx]
    triangles[idx] := byte[dtriangles][idx]    
    ' updating lowest/highest values
    if pulses[idx] < low
      low := pulses[idx]
    if pulses2[idx] < low
      low := pulses2[idx]
    if triangles[idx] < low
      low := triangles[idx]
    if pulses[idx] > high
      high := pulses[idx]
    if pulses2[idx] > high
      high := pulses2[idx]
    if triangles[idx] > high
      high := triangles[idx]
    idx++
  pulses[idx] := 0
  pulses2[idx] := 0
  triangles[idx] := 0
  mask := 0
  speed := init_speed

  Debounce
  
  repeat
    ' Raise Pitch
    if game.button(NES1_A)
      if low <> 1              ' If not lowest, decrement all values
        idx := 0
        repeat pcount
          pulses[idx] -= 1
          pulses2[idx] -= 1
          triangles[idx] -= 1
          idx++
        low--
        high--
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed)
    ' Lower Pitch
    if game.button(NES1_B)
      if high <> 255
        idx := 0
        repeat pcount
          pulses[idx] += 1
          pulses2[idx] += 1
          triangles[idx] += 1
          idx++
        low++
        high++
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed) 
    ' Make Faster
    if game.button(NES1_UP)
      if speed > 200_000
        speed -= 100_000
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed) 
    ' Make Slower
    if game.button(NES1_DOWN)
      if speed < 10_000_000
        speed += 100_000
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed)
    ' Decrement Distortion
    if game.button(NES1_LEFT)
      if mask > 0      
        mask--
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed)
    ' Increment Distortion
    if game.button(NES1_RIGHT)
      if mask < 255
        mask++
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed)
    ' Just Play Note
    if game.button(NES1_START)
      BitPlayer(chans, @pulses, dvs1, @pulses2, dvs2, @triangles, tvs,  samples, nvs, speed)      
    ' Return to Caller
    if game.button(NES1_SELECT)
      if distort == 3
        Return
      SFX
      
PUB SFX
  ' Init Program Index
  sounds := 54

  ' Show that we made it into the SFX Menu
  Flash(Green, 3_000_000)
  
  repeat
    if game.button(NES1_A)
      distort := 0 
      SFXPicker(program_index)
    if game.button(NES1_B)
      Debounce
      distort := 1 
      SFXPicker(program_index)
    if game.button(NES1_RIGHT)
      if program_index == sounds
        program_index := 0
      else
        program_index++
      Flash(Blue, 3_000_000)
      Debounce
    if game.button(NES1_LEFT)
      if program_index == 0
        program_index := sounds
      else
        program_index--
      Flash(Blue, 3_000_000)
      Debounce
    if game.button(NES1_SELECT)
      Reboot
    
PUB SFXPicker(Index)
  ' User has made selection of sound to run, this routine takes that selection (an integer)
  ' and runs the sound accociated with it (case/switch)
  case Index
    0:
      FootAttack
    1:
      Grow
    2:
      MarioExplosion
    3:
      MarioBrick
    4:
      MarioCoin
    5:
      MarioPowerUP
    6:
      MarioOneUp
    7:
      MarioJump
    8:
      MarioBump
    9:
      MarioPipe
    10:
      MarioStomp
    11:
      MarioSmack
    12:
      MarioFlag
    13:
      MarioBullet
    14:
      MarioBowser
    15:
      MegaDeath
    16:
      MegaBlast
    17:
      MegaLand
    18:
      MegaAttacked
    19:
      MegaEnemyDefeat
    20:
      MegaPowerupEnergyPulse
    21:
      MegaBomber
    22:
      MegaBigEyeLand
    23:
      MegaCutman
    24:
      MegaCutmanDeath
    25:
      MegaOontz  '
    26:
      MegaLazer
    27:
      MegaElecBrick
    28:
      MegaElecman  '
    29:
      MegaMetShell  '   
    30:
      TMNTStart
    31:
      TMNTEnemyXplode
    32:
      TMNTDoorBreak
    33:
      TMNTBoulder
    34:
      TMNTElevator
    35:
      TMNTRodneyBeamI
    36:
      TMNTRodneyBeamII
    37:
      TMNTDeath
    38:
      TMNTRocksteadyDrill
    39:
      TMNTRocksteadyGun
    40:
      TMNTGlassBreak
    41:
      TMNTPizza
    42:
      TMNTSplash
    43:
      TMNTMouserChomp
    44:
      TMNTAttackBaxter
    45:
      TMNTBaxterXplodes
    46:
      TMNTIceBall
    47:
      TMNTSnowPlow
    48:
      TMNTSnowJump
    49:
      TMNTSnowEnd
    50:
      TMNTCar
    51:
      TMNTBaxterShoot           
    52:
      TMNT200
    53:
      TMNTLazer
    54:
      TMNTTubeLazer
        
PUB FootAttack
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @footattacksamples, @footattackvolumes2, 3_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @footattacksamples, @footattackvolumes2, 3_000_000)

PUB Grow
  if distort == 1
    Distorter($08, @growpitches, @growdvs, 0, 0, 0, 0, 0, 0, 3_000_000)
  else
    BitPlayer($08, @growpitches, @growdvs, 0, 0, 0, 0, 0, 0, 3_000_000)
 
PUB MarioExplosion
  if distort == 1
    Distorter($08, @marioexplosionpitches, @marioexplosiondvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @marioexplosionpitches, @marioexplosiondvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB MarioBrick
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @mariobricksamples, @mariobrickvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @mariobricksamples, @mariobrickvolumes, 2_000_000)
      
PUB MarioCoin
  if distort == 1
    Distorter($08, @mariocoinpitches, @mariocoindvs, 0, 0, 0, 0, 0, 0, 3_000_000)
  else
    BitPlayer($08, @mariocoinpitches, @mariocoindvs, 0, 0, 0, 0, 0, 0, 3_000_000)
      
PUB MarioPowerUP
  if distort == 1
    Distorter($08, @mariopoweruppitches,@mariopowerupdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($08, @mariopoweruppitches,@mariopowerupdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
    
PUB MarioOneUP
  if distort == 1
    Distorter($08, @mariooneuppitches, @mariooneupdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($08, @mariooneuppitches, @mariooneupdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
      
PUB MarioJump
  if distort == 1
    Distorter($08, @mariojumppitches,@mariojumpdvs, 0, 0, 0, 0, 0, 0, 1_000_000)
  else
    BitPlayer($08, @mariojumppitches,@mariojumpdvs, 0, 0, 0, 0, 0, 0, 1_000_000)
    
PUB MarioBump
  if distort == 1
    Distorter($08, @mariobumppitches,@mariobumpdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariobumppitches,@mariobumpdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
PUB MarioPipe
  if distort == 1
    Distorter($08, @mariopipepitches,@mariopipedvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariopipepitches,@mariopipedvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
PUB MarioStomp
  if distort == 1
    Distorter($08, @mariostomppitches,@mariostompdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariostomppitches,@mariostompdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB MarioSmack
  if distort == 1
    Distorter($08, @mariosmackpitches,@mariosmackdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariosmackpitches,@mariosmackdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
PUB MarioFlag 
  if distort == 1
    Distorter($08, @marioflagpitches,@marioflagdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @marioflagpitches,@marioflagdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
PUB MarioBullet 
  if distort == 1
    Distorter($08, @mariobulletpitches,@mariobulletdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariobulletpitches,@mariobulletdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB MarioBowser
  if distort == 1
    Distorter($08, @mariobowserpitches,@mariobowserdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @mariobowserpitches,@mariobowserdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB MegaDeath
  if distort == 1
    Distorter($0C, @megadeathpitches1, @megadeathdvs,@megadeathpitches2,@megadeathdvs, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($0C, @megadeathpitches1, @megadeathdvs,@megadeathpitches2,@megadeathdvs, 0, 0, 0, 0, 2_000_000)
    
PUB MegaBlast
  if distort == 1
    Distorter($08, @megablastpitches, @megablastdvs, 0, 0, 0, 0, 0, 0, 3_000_000)
  else
    BitPlayer($08, @megablastpitches, @megablastdvs, 0, 0, 0, 0, 0, 0, 3_000_000)
    
PUB MegaLand
  if distort == 1
    Distorter($08, @megalandpitches, @megalanddvs, 0, 0, 0, 0, 0, 0, 3_000_000)
  else
    BitPlayer($08, @megalandpitches, @megalanddvs, 0, 0, 0, 0, 0, 0, 3_000_000)
    
PUB MegaAttacked
  if distort == 1
    Distorter($0B, @megaattackedpulsepitches, @megaattackedpulsevolumes, 0, 0, @megattackedtripitches, @megattackedtrivolumes, @megaattackednoises, @megaattackednoisesvolumes, 2_000_000)
  else
    BitPlayer($0B, @megaattackedpulsepitches, @megaattackedpulsevolumes, 0, 0, @megattackedtripitches, @megattackedtrivolumes, @megaattackednoises, @megaattackednoisesvolumes, 2_000_000)
    
PUB MegaEnemyDefeat
  if distort == 1
    Distorter($0B, @megaEDPpitches, @megaEDPdvs, 0, 0, @megaEDTpitches, @megaEDTvolumes, @megaEDNpitches, @megaEDNvolumes, 2_000_000)
  else
    BitPlayer($0B, @megaEDPpitches, @megaEDPdvs, 0, 0, @megaEDTpitches, @megaEDTvolumes, @megaEDNpitches, @megaEDNvolumes, 2_000_000)
    
PUB MegaPowerupEnergyPulse
  if distort == 1
    Distorter($0C, @megaenergypitches1, @magaenergydvs1, @megaenergypitches2, @magaenergydvs2, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($0C, @megaenergypitches1, @magaenergydvs1, @megaenergypitches2, @magaenergydvs2, 0, 0, 0, 0, 2_000_000)
    
PUB MegaBomber
  if distort == 1
    Distorter($0A, @megabomberpulsepitches, @megabomberdvs, 0, 0, @megabombertripitches, @megabombervolumes, 0, 0, 2_000_000)
  else
    BitPlayer($0A, @megabomberpulsepitches, @megabomberdvs, 0, 0, @megabombertripitches, @megabombervolumes, 0, 0, 2_000_000)
    
PUB MegaBigEyeLand
  if distort == 1
    Distorter($0A, @megabigeyelandpulsepitches, @megabigeyelanddvs, 0, 0, @megabigeyelandtripitches, @megabigeyelandvolumes, 0, 0, 2_000_000)
  else
    BitPlayer($0A, @megabigeyelandpulsepitches, @megabigeyelanddvs, 0, 0, @megabigeyelandtripitches, @megabigeyelandvolumes, 0, 0, 2_000_000)
    
PUB MegaCutman
  if distort == 1
    Distorter($09, @megacutmanpulsepitches, @megacutmandvs, 0, 0, 0, 0, @megacutmansamples, @megacutmanvolumes, 2_000_000)
  else
    BitPlayer($09, @megacutmanpulsepitches, @megacutmandvs, 0, 0, 0, 0, @megacutmansamples, @megacutmanvolumes, 2_000_000)
    
PUB MegaCutmanDeath
  if distort == 1
    Distorter($0C, @megacutmandeathpulsepitches, @megacutmandeathdvs, @megacutmandeathpulsepitches2, @megacutmandeathdvs, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($0C, @megacutmandeathpulsepitches, @megacutmandeathdvs, @megacutmandeathpulsepitches2, @megacutmandeathdvs, 0, 0, 0, 0, 2_000_000)
    
PUB MegaOontz
  if distort == 1
    Distorter($02, 0, 0, 0, 0, @megaoontzpitches, @megaoontzvolumes, 0, 0, 2_000_000)
  else
    BitPlayer($02, 0, 0, 0, 0, @megaoontzpitches, @megaoontzvolumes, 0, 0, 2_000_000)
    
PUB MegaLazer
  if distort == 1
    Distorter($08, @megalazerpitches, @megalazerdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($08, @megalazerpitches, @megalazerdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
    
PUB MegaElecBrick
  if distort == 1
    Distorter($03, 0, 0, 0, 0, @megaelecbrickpitches, @megaelecbrickvolumes, @megaelecbricksamples, @megaelecbricknvolumes, 2_000_000) 
  else
    BitPlayer($03, 0, 0, 0, 0, @megaelecbrickpitches, @megaelecbrickvolumes, @megaelecbricksamples, @megaelecbricknvolumes, 2_000_000) 
    
PUB MegaElecman
  if distort == 1
    Distorter($02, 0, 0, 0, 0, @megaelecmanpitches, @megaelecmanvolumes, 0, 0, 2_000_000) 
  else
    BitPlayer($02, 0, 0, 0, 0, @megaelecmanpitches, @megaelecmanvolumes, 0, 0, 2_000_000) 
    
PUB MegaMetShell
  if distort == 1
    Distorter($0A, @megametshellpitches, @megametshelldvs, 0, 0, @megametshelltpitches, @megametshellvolumes, 0, 0, 2_000_000)
  else
    BitPlayer($0A, @megametshellpitches, @megametshelldvs, 0, 0, @megametshelltpitches, @megametshellvolumes, 0, 0, 2_000_000)
    
PUB TMNTStart
  if distort == 1
    Distorter($08, @tmntstartpitches, @tmntstartdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($08, @tmntstartpitches, @tmntstartdvs, 0, 0, 0, 0, 0, 0, 2_000_000)
    
PUB TMNTEnemyXplode
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntenemyxplodesamples, @tmntenemyxplodevolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntenemyxplodesamples, @tmntenemyxplodevolumes, 2_000_000)
    
PUB TMNTDoorBreak
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntdoorbreaksamples, @tmntdoorbreakvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntdoorbreaksamples, @tmntdoorbreakvolumes, 2_000_000)
    
PUB TMNTBoulder
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntbouldersamples, @tmntbouldervolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntbouldersamples, @tmntbouldervolumes, 2_000_000)
    
PUB TMNTElevator
  if distort == 1
    Distorter($08, @tmntelevatorpitches, @tmntelevatordvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @tmntelevatorpitches, @tmntelevatordvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB TMNTRodneyBeamI
  if distort == 1
    Distorter($08, @tmntrodneybeamIpitches, @tmntrodneybeamIdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @tmntrodneybeamIpitches, @tmntrodneybeamIdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB TMNTRodneyBeamII
  if distort == 1
    Distorter($08, @tmntrodneybeamIIpitches, @tmntrodneybeamIIdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @tmntrodneybeamIIpitches, @tmntrodneybeamIIdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    
PUB TMNTDeath
  if distort == 1
    Distorter($09, @tmntdeathpitches, @tmntdeathdvs, 0, 0, 0, 0, @tmntdeathsamples, @tmntdeathvolumes, 1_500_000)
  else
    BitPlayer($09, @tmntdeathpitches, @tmntdeathdvs, 0, 0, 0, 0, @tmntdeathsamples, @tmntdeathvolumes, 1_500_000)
    
PUB TMNTRocksteadyDrill
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadydrillsamples, @tmntrocksteadydrillvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadydrillsamples, @tmntrocksteadydrillvolumes, 2_000_000)
    
PUB TMNTRocksteadyGun
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadygunsamples, @tmntrocksteadygunvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntrocksteadygunsamples, @tmntrocksteadygunvolumes, 2_000_000)
    
PUB TMNTGlassBreak
  if distort == 1
    Distorter($09, @tmntglassbreakpitches, @tmntglassbreakdvs, 0, 0, 0, 0, @tmntglassbreaksamples, @tmntglassbreakvolumes, 1_500_000)
  else
    BitPlayer($09, @tmntglassbreakpitches, @tmntglassbreakdvs, 0, 0, 0, 0, @tmntglassbreaksamples, @tmntglassbreakvolumes, 1_500_000)
    
PUB TMNTPizza
  if distort == 1
    Distorter($08, @tmntpizzapitches, @tmntpizzadvs, 0, 0, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($08, @tmntpizzapitches, @tmntpizzadvs, 0, 0, 0, 0, 0, 0, 2_000_000)
    
PUB TMNTSplash
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntsplashsamples, @tmntsplashvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntsplashsamples, @tmntsplashvolumes, 2_000_000)
    
PUB TMNTMouserChomp
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntmouserchompsamples, @tmntmouserchompvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntmouserchompsamples, @tmntmouserchompvolumes, 2_000_000)
    
PUB TMNTAttackBaxter
  if distort == 1
    Distorter($09, @tmntattackbaxterpitches, @tmntattackbaxterdvs, 0, 0, 0, 0, @tmntattackbaxtersamples, @tmntattackbaxtervolumes, 1_500_000)
  else
    BitPlayer($09, @tmntattackbaxterpitches, @tmntattackbaxterdvs, 0, 0, 0, 0, @tmntattackbaxtersamples, @tmntattackbaxtervolumes, 1_500_000)
    
PUB TMNTBaxterXplodes
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    Repeat 17
      Distorter($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    Repeat 17
      BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntbaxterxplodes1, @tmntbaxterxplodev1, 2_000_000)
    
PUB TMNTIceBall
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmnticeballsamples, @tmnticeballvolumes, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmnticeballsamples, @tmnticeballvolumes, 2_000_000)
    
PUB TMNTSnowPlow
  if distort == 1
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples1, @tmntsnowplowvolumes1, 2_000_000)
    Repeat 7
      Distorter($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples2, @tmntsnowplowvolumes2, 2_000_000)
    Distorter($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples3, @tmntsnowplowvolumes3, 2_000_000)
  else
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples1, @tmntsnowplowvolumes1, 2_000_000)
    Repeat 7
      BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples2, @tmntsnowplowvolumes2, 2_000_000)
    BitPlayer($01, 0, 0, 0, 0, 0, 0, @tmntsnowplowsamples3, @tmntsnowplowvolumes3, 2_000_000)
   
PUB TMNTSnowJump
  if distort == 1
    Distorter($09, @tmntsnowjumppitches, @tmntsnowjumpdvs, 0, 0, 0, 0, @tmntsnowjumpsamples, @tmntsnowjumpvolumes, 1_500_000)
  else
    BitPlayer($09, @tmntsnowjumppitches, @tmntsnowjumpdvs, 0, 0, 0, 0, @tmntsnowjumpsamples, @tmntsnowjumpvolumes, 1_500_000)
    
PUB TMNTSnowEnd
  if distort == 1
    Distorter($0C, @tmntsnowendpitches1a, @tmntsnowenddvs1, @tmntsnowendpitches1b, @tmntsnowenddvs1, 0, 0, 0, 0, 2_000_000)
    Distorter($0C, @tmntsnowendpitches2a, @tmntsnowenddvs2, @tmntsnowendpitches2b, @tmntsnowenddvs2, 0, 0, 0, 0, 2_000_000)
    Distorter($0C, @tmntsnowendpitches3a, @tmntsnowenddvs3, @tmntsnowendpitches3b, @tmntsnowenddvs3, 0, 0, 0, 0, 2_000_000)
  else
    BitPlayer($0C, @tmntsnowendpitches1a, @tmntsnowenddvs1, @tmntsnowendpitches1b, @tmntsnowenddvs1, 0, 0, 0, 0, 2_000_000)
    BitPlayer($0C, @tmntsnowendpitches2a, @tmntsnowenddvs2, @tmntsnowendpitches2b, @tmntsnowenddvs2, 0, 0, 0, 0, 2_000_000)
    BitPlayer($0C, @tmntsnowendpitches3a, @tmntsnowenddvs3, @tmntsnowendpitches3b, @tmntsnowenddvs3, 0, 0, 0, 0, 2_000_000)
    
PUB TMNTCar
  if distort == 1
    Distorter($09, @tmntcarpitches, @tmntcardvs, 0, 0, 0, 0, @tmntcarsamples, @tmntcarvolumes, 2_000_000)
  else
    BitPlayer($09, @tmntcarpitches, @tmntcardvs, 0, 0, 0, 0, @tmntcarsamples, @tmntcarvolumes, 2_000_000)
    
PUB TMNTBaxterShoot
  if distort == 1
    Distorter($09, @tmntbaxtershootpitches, @tmntbaxtershootdvs, 0, 0, 0, 0, @tmntbaxtershootsamples, @tmntbaxtershootvolumes, 1_500_000)
  else
    BitPlayer($09, @tmntbaxtershootpitches, @tmntbaxtershootdvs, 0, 0, 0, 0, @tmntbaxtershootsamples, @tmntbaxtershootvolumes, 1_500_000)
    
PUB TMNT200
  if distort == 1
    Distorter($08, @tmnt200pitches, @tmnt200dvs, 0, 0, 0, 0, 0, 0, 1_500_000) 
  else
    BitPlayer($08, @tmnt200pitches, @tmnt200dvs, 0, 0, 0, 0, 0, 0, 1_500_000) 
      
PUB TMNTLazer
  if distort == 1
    Distorter($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    Distorter($08, @tmntlazer1pitches, @tmntlazer1dvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    Distorter($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    Distorter($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000) 
    Distorter($08, @tmntlazer1pitches, @tmntlazer1dvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    Repeat 7
      Distorter($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    BitPlayer($08, @tmntlazer1pitches, @tmntlazer1dvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    BitPlayer($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    BitPlayer($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000) 
    BitPlayer($08, @tmntlazer1pitches, @tmntlazer1dvs, 0, 0, 0, 0, 0, 0, 1_500_000)
    Repeat 7
      BitPlayer($08, @tmntlazercpitches, @tmntlazercdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
PUB TMNTTubeLazer
  if distort == 1
    Distorter($08, @tmnttubelazerpitches, @tmnttubelazerdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
  else
    BitPlayer($08, @tmnttubelazerpitches, @tmnttubelazerdvs, 0, 0, 0, 0, 0, 0, 1_500_000)
      
{{
*************************************************************
|                   NES Style SFX player                    |
*************************************************************
}}
PUB BitPlayer(chans, p1, dvs1, p2, dvs2, p3, v, s, v2, delay)
  idx := 0
  ' Get repetitions / amount of pitches to play
  if (chans & %1000)
    repeat while (byte[p1][idx] > 0)
      idx++
  elseif (chans & %0100)
    repeat while (byte[p2][idx] > 0)
      idx++ 
  elseif (chans & %0010)
    repeat while (byte[p3][idx] > 0)
      idx++
  else
    repeat while (byte[s][idx] > 0)
      idx++
  pcount := idx

  idx := 0
  if (chans & %1000)
    'Unpack data Pulse1 data (Pre-unpacking instead of live unpacking due to priority performance of play loop)
    repeat pcount
      p1volumes[idx] := byte[dvs1][idx] & $1F
      p1dutys[idx] := (byte[dvs1][idx] & $E0) >> 4
      idx++

  idx := 0  
  if (chans & %0100)
    'Unpack data Pulse2 data (Pre-unpacking instead of live unpacking due to priority performance of play loop)
    repeat pcount
      p2volumes[idx] := byte[dvs2][idx] & $1F
      p2dutys[idx] := (byte[dvs2][idx] & $E0) >> 4
      idx++

  idx := 0
  repeat pcount
    if (chans & %1000)
      pcm.PulseWave(1, p1dutys[idx], 4)
      pcm.Playnote (1, byte[p1][idx], p1volumes[idx], 0, 0, mask, 3)      
    if (chans & %0100)
      pcm.PulseWave(2, p2dutys[idx], 4)
      pcm.Playnote (2, byte[p2][idx], p2volumes[idx], 0, 0, mask, 3)
    if (chans & %0010)
      pcm.TriangleWave(3, 8, 4)
      pcm.Playnote (3, byte[p3][idx], byte[v][idx], 0, 0, mask, 3)    
    if (chans & %0001)
      pcm.NoiseWave(4)
      pcm.Playnote(4, byte[s][idx], byte[v2][idx], 0, 0, 0, 10)
    idx++
    waitcnt(delay + cnt)
  pcm.Silent

PUB Flash(Color, Delay)
  outa[Color] :=1
  waitcnt(Delay + cnt)
  outa[Color] :=0

PUB Debounce
  waitcnt(40_000_000 + cnt)
  
PUB NoiseJam
  repeat while not game.button(NES1_A)
  Flash(Red, 3_000_000)
  pitch := 9
  inst := 1
  repeat
    if game.button(NES1_A)
      if inst == 1
        pcm.PulseWave(2, pulselvl, 0)
      if inst == 2
        pcm.SineWave(2, pulselvl, 0)
      if inst == 3
        pcm.TriangleWave(2, pulselvl, 0)                  
      pcm.Playnote (2, pitch, 3, 0, 0, 0, 5)

    if game.button(NES1_B)
      inst++
      if inst > 3
        inst := 1 
      waitcnt(clkfreq/((168*4)/60)+cnt)
    
    if game.button(NES1_UP)
      pcm.NoiseWave(3)
      pcm.Playnote (3, pitch, 3, 0, 0, 0, 5)

    if game.button(NES1_LEFT)
      pitch--
      waitcnt(clkfreq/((168*4)/10)+cnt)
      if pitch < 1
        pitch := 9 
    if game.button(NES1_DOWN)
      pcm.PulseWave(1, pulselvl, 0)
      pcm.AddNoise(1,20,$1FFFFFFF) 
      pcm.Playnote (1, pitch+5, 3, 0, 0, 0, 5)
    if game.button(NES1_RIGHT)
      pitch++
      waitcnt(clkfreq/((168*4)/10)+cnt)
      if pitch > 100
        pitch := 9  
    if game.button(NES1_START)
      pulselvl--
      if (pulselvl < 0)
        pulselvl :=8
    if game.button(NES1_SELECT)
      Reboot

DAT
' Format for dv BYTE (duties and volumes) is dddvvvvv
'       Valid range of duties is 1-8 (fits into 3 bits)
'       Valid range of volumes is 0-20 (fits into 5 bits)
'       Conclusion: can fit both duties and volumes packed into 1 byte
growpitches          BYTE 24,32,24,19,16,11,16,30,24,20,15,20,15,11,9,7,9,27,21,18,13,18,13,10,8,6,8,0
growdvs              BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83

footattacksamples    BYTE 12,127,63,32,18,17,16,16,16,15,0
footattackvolumes    BYTE 16,2,4,3,4,7,9,10,11,12
footattackvolumes2    BYTE 10,3,4,3,4,5,6,7,7,7

marioexplosionpitches   BYTE 88,88,93,93,99,99,106,43,43,50,50,57,57,65,65,74,74,84,84,96,96,110,110,125,125,142,142,163,163,0
marioexplosiondvs       BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83

mariobricksamples    BYTE 16,16,13,13,13,13,32,32,17,17,18,18,255,255,32,32,22,22,13,13,0
mariobrickvolumes    BYTE 3,3,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6

mariocoinpitches     BYTE 11,11,11,12,12,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0
mariocoindvs         BYTE $87,$83,$83,$83,$83,$83,$83,$84,$84,$84,$84,$84,$84,$85,$85,$85,$85,$85,$85,$86,$86,$86,$86,$86,$86,$87,$87,$87

mariopoweruppitches  BYTE 20,49,49,49,32,32,30,30,46,46,46,46,30,30,28,28,43,43,43,43,36,36,27,27,37,37,37,37,27,27,25,25,25,25,25,25,25,25,25,25,25,25,25,0
mariopowerupdvs      BYTE $87,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$87,$87,$89,$89,$89,$89,$89,$89,$89,$89,$89

mariooneuppitches    BYTE 9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,0
mariooneupdvs        BYTE $88,$88,$88,$83,$83,$84,$84,$85,$85,$86,$86,$87,$87,$88,$88,$89,$89,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88

mariojumppitches     BYTE 43,43,43,44,44,44,44,44,44,44,44,41,41,41,41,39,39,39,39,36,36,36,36,34,34,34,34,32,32,32,32,30,30,0
mariojumpdvs         BYTE $85,$85,$85,$85,$43,$43,$43,$43,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44

mariobumppitches     BYTE 66,66,75,75,86,86,86,0
mariobumpdvs         BYTE $83,$83,$83,$83,$83,$87,$87

mariopipepitches     BYTE 9,9,19,19,9,9,19,19,38,38,77,77,155,155,311,311,9,9,19,19,9,9,19,19,38,38,77,77,155,155,311,311,9,9,19,19,9,9,19,19,38,38,77,77,155,155,311,311,0
mariopipedvs         BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
         
mariostomppitches    BYTE 28,28,28,28,28,28,28,27,27,27,19,19,19,19,19,0
mariostompdvs        BYTE $88,$88,$87,$86,$84,$85,$85,$85,$88,$87,$87,$86,$85,$84,$83

mariosmackpitches    BYTE 27,27,27,27,27,19,19,19,19,19,19,17,17,0
mariosmackdvs        BYTE $85,$85,$85,$85,$85,$83,$85,$85,$85,$85,$85,$85,$85

marioflagpitches     BYTE 58,58,58,58,55,55,55,55,52,52,52,52,49,49,49,49,46,46,46,46,43,43,43,43,41,41,41,41,38,38,38,38,36,36,36,36,34,34,34,34,32,32,32,32,30,30,30,30,28,28,28,28,27,27,27,27,25,25,25,25,23,23,23,23,22,22,22,22,21,21,21,21,19,19,19,19,18,18,18,18,17,17,17,17,16,16,16,16,15,15,15,15,14,14,14,14,13,13,13,13,0
marioflagdvs         BYTE $85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85

mariobulletpitches   BYTE 66,66,44,44,29,29,28,28,0
mariobulletdvs       BYTE $83,$83,$83,$83,$86,$86,$86,$86

mariobowserpitches   BYTE 34,34,37,37,39,39,42,42,44,44,47,47,51,51,54,54,58,58,61,61,66,66,70,70,75,75,79,79,84,84,90,90,95,95,102,102,115,115,122,122,130,130,138,138,147,147,155,155,0
mariobowserdvs       BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83

megadeathpitches1    BYTE 255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,255,12,18,23,29,3,9,14,20,58,32,40,43,49,93,255,0
megadeathpitches2    BYTE 255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,255,12,19,25,31,3,9,16,22,61,34,42,46,52,99,255,0
megadeathdvs         BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89,$89

megablastpitches     BYTE 29,21,21,17,13,9,5,29,29,24,20,16,12,4,0
megablastdvs         BYTE $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43

megalandpitches      BYTE 57,28,226,197,222,197,0
megalanddvs          BYTE $43,$43,$43,$43,$43,$43

megaattackedpulsepitches    BYTE 25,6,63,63,255,10,9,7,6,6,2,1,255,255,255,255,255,0
megaattackednoises          BYTE 22,32,63,63,18,16,22,127,63,32,22,18,17,16,22,127,11,0
megattackedtripitches       BYTE 25,255,6,12,3,23,255,1,1,1,255,255,255,255,255,255,255,0
megaattackedpulsevolumes    BYTE $43,$43,$43,$43,$54,$46,$46,$46,$46,$46,$46,$46,$94,$94,$94,$94,$94
megaattackednoisesvolumes   BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
megattackedtrivolumes       BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

MegaEDPpitches       BYTE 9,17,25,1,9,17,57,33,41,49,90,66,74,82,123,98,106,115,0
MegaEDTpitches       BYTE 22,40,59,3,22,40,134,78,97,115,209,154,173,189,255,230,246,255,0
MegaEDNpitches       BYTE 127,63,32,22,18,17,16,15,14,13,14,13,12,11,10,255,127,63,0
MegaEDPdvs           BYTE $54,$54,$54,$54,$94,$46,$46,$46,$46,$46,$46,$46,$94,$94,$94,$94,$94,$94
MegaEDTvolumes       BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
MegaEDNvolumes       BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

megaenergypitches1   BYTE 23,23,22,22,255,18,17,17,255,15,14,14,255,11,10,10,255,8,8,8,255,18,17,17,15,15,14,14,255,11,10,10,0
megaenergypitches2   BYTE 15,15,14,14,255,12,11,11,255,10,9,9,255,7,6,6,255,5,5,5,255,11,11,11,9,9,9,9,255,7,6,6,0
magaenergydvs1       BYTE $94,$83,$94,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$83,$83,$83,$83,$8B,$83,$83,83
magaenergydvs2       BYTE $54,$47,$54,$47,$4B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$8B,$83,$83,$83,$83,$83,$83,$83,$8B,$83,$83,83

megabomberpulsepitches   BYTE 13,15,17,19,21,23,25,0
megabombertripitches     BYTE 30,33,37,41,45,49,54,0
megabomberdvs            BYTE $43,$43,$43,$43,$43,$43,$43
megabombervolumes        BYTE 3,3,3,3,3,3,3

megabigeyelandpulsepitches BYTE 21,34,34,255,21,11,34,15,255,15,0
megabigeyelandtripitches   BYTE 75,11,255,75,11,62,194,197,197,197,0
megabigeyelanddvs          BYTE $43,$43,$43,$4B,$43,$43,$43,$43,$4B,$47
megabigeyelandvolumes      BYTE 3,3,3,3,3,3,3,3,3,3

megacutmanpulsepitches     BYTE 4,4,4,3,3,255,4,4,3,3,3,2,3,3,4,4,4,3,3,2,3,3,4,4,4,3,2,2,3,3,4,4,4,3,3,2,3,255,0
megacutmansamples          BYTE 15,18,15,14,14,11,15,18,15,14,11,127,11,14,15,18,15,14,11,127,11,14,15,18,15,14,11,127,11,14,15,18,15,14,11,127,127,11,0 
megacutmandvs              BYTE $23,$23,$23,$23,$23,$2B,$23,$23,$23,$23,$23,$23,$23,$24,$24,$24,$24,$26,$26,$26,$26,$27,$27,$27,$27,$29,$29,$29,$29,$2A,$2A,$2A,$2A,$28,$28,$27,$27,$2A
megacutmanvolumes          BYTE 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,8,8,8,8,9,9,9,9,10,10,10,10,10

megacutmandeathpulsepitches  BYTE 13,20,26,1,7,13,19,58,32,38,45,51,57,97,70,76,83,89,136,136,0
megacutmandeathpulsepitches2 BYTE 31,5,11,17,24,62,36,43,49,55,95,68,74,81,87,127,100,106,113,152,0
megacutmandeathdvs           BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83

megaoontzpitches BYTE 43,55,2,14,26,38,50,127,73,85,97,110,189,134,145,159,237,0
megaoontzvolumes BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

megalazerpitches BYTE 32,32,64,63,31,32,64,63,31,32,64,63,32,32,64,63,31,32,64,63,31,32,64,0
megalazerdvs     BYTE $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$44,$44,$44

megaelecbrickpitches  BYTE 52,52,51,50,50,49,48,48,47,47,46,45,45,44,44,43,43,42,42,41,40,40,40,39,39,38,38,37,37,36,36,35,35,34,34,33,33,33,32,32,31,31,31,30,30,29,29,29,0
megaelecbrickvolumes  BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
megaelecbricksamples  BYTE 16,14,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,0
megaelecbricknvolumes BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

megaelecmanpitches BYTE 18,19,18,16,14,12,14,16,18,19,18,16,14,12,14,16,0
megaelecmanvolumes BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

megametshellpitches  BYTE 17,215,215,215,0
megametshelldvs      BYTE 3,3,3,3
megametshelltpitches BYTE 3,71,71,71,0
megametshellvolumes  BYTE 3,3,3,3

tmntstartpitches BYTE 45,36,44,11,36,35,41,41,61,34,31,47,14,45,36,44,11,36,35,41,41,61,34,31,47,14,45,36,44,11,36,35,41,41,61,34,31,47,14,45,36,44,11,36,35,41,41,61,0
tmntstartdvs     BYTE $85,$85,$83,$83,$85,$85,$83,$83,$85,$85,$86,$83,$83,$85,$85,$85,$84,$85,$85,$84,$85,$85,$85,$86,$84,$85,$86,$86,$85,$85,$86,$86,$85,$85,$86,$85,$85,$84,$84,$85,$85,$85,$84,$85,$85,$84,$85,$85

tmntenemyxplodesamples BYTE 22,127,127,63,32,22,18,127,127,63,32,63,63,63,63,127,255,255,127,127,127,255,255,127,255,255,255,127,255,255,127,127,255,255,255,127,127,255,127,127,127,255,0
tmntenemyxplodevolumes BYTE 3,4,4,5,6,7,4,3,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,8,8,8,8,8,9,9,9,9,9,9,9

tmntdoorbreaksamples BYTE 255,127,255,255,16,32,16,22,22,18,18,18,22,22,63,63,63,32,22,0
tmntdoorbreakvolumes BYTE 10,3,3,5,3,4,3,3,4,4,4,4,4,4,5,5,5,5,5

tmntbouldersamples BYTE 255,127,255,127,255,255,8,8,127,127,127,127,127,127,127,127,255,255,127,127,127,255,255,255,127,127,255,127,255,255,8,8,127,127,127,127,127,127,127,127,255,255,127,127,127,127,255,255,127,127,127,127,255,255,255,0
tmntbouldervolumes BYTE 10,3,3,7,8,8,10,10,3,3,3,3,6,6,6,6,7,7,8,8,8,8,8,8,8,3,3,7,8,8,10,10,3,3,3,3,6,6,6,6,7,7,8,8,8,8,8,8,8,8,8,8,9,9,9

tmntelevatorpitches BYTE 39,54,51,47,44,41,39,39,39,39,40,40,40,40,40,40,40,40,40,0
tmntelevatordvs     BYTE $23,$24,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23

tmntrodneybeamIpitches BYTE 20,18,53,60,69,79,47,54,62,71,0
tmntrodneybeamIdvs     BYTE $15,$24,$24,$23,$23,$23,$24,$23,$23,$23

tmntrodneybeamIIpitches BYTE 20,18,21,24,28,32,37,12,95,95,4,4,12,12,12,10,7,6,4,3,3,0
tmntrodneybeamIIdvs     BYTE $25,$25,$25,$25,$25,$25,$25,$25,$44,$44,$44,$44,$44,$44,$43,$43,$43,$43,$43,$43,$43

tmntdeathpitches BYTE 97,97,97,97,97,97,97,111,126,142,163,184,209,237,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,0
tmntdeathdvs     BYTE $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$26,$26,$26,$26,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
tmntdeathsamples BYTE 18,18,18,127,127,127,127,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,18,18,18,18,18,22,22,22,22,32,32,32,32,32,32,32,63,63,0
tmntdeathvolumes BYTE 3,3,3,3,3,3,3,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7

tmntrocksteadydrillsamples BYTE 255,8,8,127,127,127,127,127,127,127,127,127,32,32,32,255,255,255,63,63,63,127,127,127,127,127,127,127,127,127,63,63,63,63,63,63,63,63,63,63,63,63,18,18,18,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,63,63,255,255,255,0
tmntrocksteadydrillvolumes BYTE 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4

tmntrocksteadygunsamples BYTE 63,18,17,17,63,18,17,17,63,18,17,17,63,18,17,17,63,18,17,17,0
tmntrocksteadygunvolumes BYTE 4,8,8,3,4,8,8,3,4,8,8,3,4,8,8,3,4,8,8,3

tmntglassbreakpitches BYTE 53,53,53,53,53,53,53,53,41,41,41,41,41,41,41,41,69,92,122,163,215,255,4,6,8,255,1,2,3,3,2,3,1,1,3,3,3,3,0
tmntglassbreakdvs     BYTE $47,$47,$47,$47,$47,$47,$47,$47,$43,$43,$43,$43,$43,$43,$43,$43,$45,$45,$47,$47,$47,$47,$47,$47,$47,$4A,$47,$47,$47,$47,$47,$4A,$4A,$48,$48,$29,$47,$47
tmntglassbreaksamples BYTE 255,8,127,255,63,127,63,32,22,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,17,17,17,17,17,17,17,0
tmntglassbreakvolumes BYTE 10,10,3,8,3,3,3,3,4,5,5,5,5,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,9,9,9,9

tmntpizzapitches BYTE 71,71,71,28,28,25,24,24,24,23,23,21,20,20,20,19,19,18,17,17,17,16,16,15,13,13,13,12,12,11,10,10,10,19,19,18,17,17,17,16,16,15,13,13,13,12,12,11,11,10,10,19,19,18,18,17,16,16,15,15,13,13,13,12,12,11,11,11,11,7,53,0
tmntpizzadvs     BYTE$26,$26,$26,$24,$24,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$24,$24,$24,$24,$25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27

tmntsplashsamples BYTE 32,18,18,18,32,22,22,8,8,17,17,13,13,15,16,16,14,14,13,13,13,13,13,15,15,16,16,14,13,13,14,14,15,15,15,14,14,13,13,14,14,13,12,12,12,12,0
tmntsplashvolumes BYTE 3,5,5,5,3,7,7,10,10,3,3,4,4,4,5,5,6,6,7,7,7,6,6,6,6,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8

tmntmouserchompsamples BYTE 255,17,18,32,63,127,32,18,0
tmntmouserchompvolumes BYTE 9,5,4,4,3,4,4,5

tmntattackbaxterpitches BYTE 95,95,75,75,107,107,107,107,107,107,65,65,65,65,65,65,65,87,116,155,206,255,255,255,255,255,255,255,255,255,0
tmntattackbaxterdvs     BYTE $26,$26,$26,$26,$27,$27,$27,$27,$28,$28,$25,$25,$25,$25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26
tmntattackbaxtersamples BYTE 32,32,32,32,63,63,22,22,127,127,127,127,63,63,32,32,22,22,18,127,127,127,127,63,63,32,32,63,63,63,0
tmntattackbaxtervolumes BYTE 10,10,10,10,11,11,3,3,4,4,4,4,5,5,6,6,7,7,4,4,3,3,4,4,4,4,5,5,5,5

tmntbaxterxplodes1 BYTE 63,127,127,127,127,127,127,127,0
tmntbaxterxplodev1 BYTE 10,3,3,3,3,3,3,3
tmntbaxterxplodes2 BYTE 127,127,127,127,127,127,127,127,0
tmntbaxterxplodev2 BYTE 9,3,3,3,3,3,3,3
tmntbaxterxplodes3 BYTE 127,127,127,127,127,127,127,127,127,127,127,127,63,63,63,63,63,63,63,63,127,127,127,127,63,63,63,63,63,63,63,63,63,63,63,63,127,127,63,63,63,63,63,63,63,63,63,63,63,63,0
tmntbaxterxplodev3 BYTE 9,3,9,9,9,9,9,9,3,3,3,3,3,3,3,3,3,3,3,3,5,5,5,5,3,6,6,6,6,6,6,6,6,6,6,6,7,7,6,6,6,6,6,6,6,6,6,6,6,7
tmntbaxterxplodes4 BYTE 63,63,63,63,127,127,127,127,127,127,127,127,127,63,63,63,63,63,63,63,63,63,63,63,127,127,127,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,127,127,127,127,127,127,127,127,127,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,0
tmntbaxterxplodev4 BYTE 7,7,7,7,6,6,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10

tmnticeballsamples BYTE 32,127,255,17,18,127,127,22,127,127,22,127,127,127,63,63,127,127,127,63,63,63,63,127,127,0
tmnticeballvolumes BYTE 3,4,4,5,5,4,6,5,5,5,7,7,7,7,8,8,8,8,8,9,9,9,9,9,9

tmntsnowplowsamples1 BYTE 255,255,255,255,255,255,255,127,127,127,127,127,127,127,22,22,0
tmntsnowplowvolumes1 BYTE 8,8,8,8,8,8,8,5,5,5,5,5,5,5,3,3
tmntsnowplowsamples2 BYTE 127,127,127,127,127,127,127,127,127,127,127,127,127,127,22,22,0
tmntsnowplowvolumes2 BYTE 6,6,6,6,6,6,6,5,5,5,5,5,5,5,3,3
tmntsnowplowsamples3 BYTE 22,22,22,22,22,127,127,127,127,127,127,127,22,22,22,22,22,22,22,127,127,127,127,127,127,127,22,22,22,22,22,22,22,127,127,127,127,127,127,127,22,22,22,22,22,22,22,127,127,127,127,127,127,127,22,22,22,22,22,22,22,0
tmntsnowplowvolumes3 BYTE 3,3,3,3,3,6,6,6,6,6,6,6,4,4,4,4,4,4,4,6,6,6,6,6,6,6,5,5,5,5,5,5,5,7,7,7,7,7,7,7,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7

tmntsnowjumppitches BYTE 80,80,80,80,80,80,80,80,80,107,142,189,250,255,255,255,255,255,255,255,255,255,255,255,255,255,255,0
tmntsnowjumpdvs     BYTE $28,$28,$28,$28,$28,$28,$28,$28,$43,$43,$43,$43,$43,$86,$86,$88,$88,$88,$88,$88,$88,$2A,$2A,$2A,$2A,$2A,$2A
tmntsnowjumpsamples BYTE 14,63,127,127,127,127,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
tmntsnowjumpvolumes BYTE 10,3,8,3,3,3,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9

tmntsnowendpitches1a BYTE 130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,121,121,121,121,121,121,121,121,121,121,121,121,121,121,121,121,113,113,113,113,113,113,113,113,113,113,113,113,113,113,113,105,105,105,105,105,105,105,105,105,105,105,105,105,105,105,0
tmntsnowendpitches1b BYTE 137, 137,137,137,137,137,137,137,137,137,137,137,137,137,137,137,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,0
tmntsnowendpitches2a BYTE 97,97,97,97,97,97,97,97,97,97,97,97,97,97,97,89,89,89,89,89,89,89,89,89,89,89,89,89,89,78,72,72,72,72,72,72,72,72,72,72,72,72,72,72,64,64,64,64,64,64,64,64,64,64,64,64,64,0
tmntsnowendpitches2b BYTE 102,102,102,102,102,102,102,102,102,102,102,102,102,102,102,93,93,93,93,93,93,93,93,93,93,93,93,93,93,82,76,76,76,76,76,76,76,76,76,76,76,76,76,76,67,67,67,67,67,67,67,67,67,67,67,67,67,0
tmntsnowendpitches3a BYTE 56,56,56,56,56,56,56,56,56,56,56,56,56,47,47,47,47,47,47,47,47,47,47,47,47,44,44,44,44,44,44,44,44,44,44,44,40,40,40,40,40,40,40,40,40,40,35,35,35,35,35,35,35,35,35,31,31,31,31,31,31,31,31,27,27,27,27,27,27,27,25,25,25,25,25,25,25,24,24,24,24,24,24,24,23,23,23,23,23,23,23,22,22,22,22,22,22,22,0
tmntsnowendpitches3b BYTE 59,59,59,59,59,59,59,59,59,59,59,59,59,50,50,50,50,50,50,50,50,50,50,50,50,46,46,46,46,46,46,46,46,46,46,46,41,41,41,41,41,41,41,41,41,41,37,37,37,37,37,37,37,37,37,33,33,33,33,33,33,33,33,29,29,29,29,29,29,29,27,27,27,27,27,27,27,25,25,25,25,25,25,25,24,24,24,24,24,24,24,23,23,23,23,23,23,23,0
tmntsnowenddvs1 BYTE $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
tmntsnowenddvs2 BYTE $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
tmntsnowenddvs3 BYTE $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45

tmntcarpitches BYTE 67,219,219,186,168,97,126,121,116,111,107,102,65,93,62,34,39,44,48,53,57,95,67,71,76,80,85,90,127,99,103,111,117,122,161,132,136,141,145,150,155,192,164,168,173,177,182,222,0
tmntcardvs     BYTE $49,$43,$43,$43,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$29
tmntcarsamples BYTE 255,255,255,255,255,255,255,255,255,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,0
tmntcarvolumes BYTE 8,8,8,8,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7

tmntbaxtershootpitches BYTE 85,85,85,85,31,31,11,23,47,94,189,255,255,255,255,255,3,7,15,32,65,130,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,10,0
tmntbaxtershootdvs     BYTE $46,$46,$46,$46,$43,$43,$48,$48,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$25,$25,$25,$25,$25,$25,$26,$26,$26,$26,$27,$27,$27,$27,$28,$28,$28,$28,$29
tmntbaxtershootsamples BYTE 32,32,14,8,8,14,14,15,15,15,16,16,16,16,17,17,18,18,18,22,22,22,32,32,32,32,32,32,63,63,63,127,127,127,127,127,127,127,127,127,0
tmntbaxtershootvolumes BYTE 4,4,5,7,7,5,5,5,5,5,5,5,5,5,5,5,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6

tmnt200pitches BYTE 31,29,27,26,24,23,21,20,19,18,17,16,15,14,13,12,11,11,10,9,9,8,8,7,7,6,6,5,5,5,4,4,4,3,3,3,3,3,2,2,2,2,2,2,1,1,1,0
tmnt200dvs     BYTE $44,$44,$44,$44,$44,$44,$44,$44,$44,$43,$43,$43,$43,$44,$44,$44,$44,$44,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46

tmntlazercpitches BYTE 14,14,0
tmntlazercdvs     BYTE $44,$43
tmntlazer1pitches BYTE 14,29,14,255,0
tmntlazer1dvs     BYTE $44,$44,$43,$4B

tmnttubelazerpitches BYTE 17,15,13,12,10,9,8,7,19,17,15,13,12,10,9,8,7,6,5,5,4,3,3,3,0
tmnttubelazerdvs     BYTE $26,$27,$25,$25,$25,$25,$25,$25,$24,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$25,$25,$25,$26
