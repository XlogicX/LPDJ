# This tool is for selecting proper values on my BassOS using my audio driver on the propeller.
# Because of the way the driver is implemented, the interface for playing a 'note' is not simple/transparent. 
# You can set up an instrument on a channel and specify a 'pitch', which is really just a value that sets
# the delay loop for how long a wave table gets played. The pitches are generally low frequency. Though
# When setting up an instrument, you can divide the wavetable up; like having square wave cycle twice in one
# wave table, or 4 times, 8 times, etc...
# So this script takes a frequency or note as input, and outputs a good suggestion of the right pitch value
# and divisor to get close. Note that the higher the divisor, the lower quality curvy waves will sound (like a sine)

import argparse
import re

# Get customisation from user
parser = argparse.ArgumentParser(description='Give note or Frequency, get a pitch and division value in return')
parser.add_argument('--note', help='A lettered note (A5, F#2, Eb3')
parser.add_argument('--freq', help='A frequency, assumed in Hz')
args = parser.parse_args()

def halfsteps(note):
	# Parse Letter and Number
	if re.match(r'[a-fA-F][#b]?\d', note):
		match = re.match(r'([a-fA-F][#b]?)(\d)', note)
		letter = match.group(1).upper()
		octave = match.group(2)
	else:
		print('invalid note')
		quit()	
	conversions = {'A':0, 'A#':1, 'Bb':1, 'B':2, 'C':3, 'C#':4, 'Db':4, 'D':5, 'D#':6, 'Eb':6, 'E':7, 'F':8, 'F#':9, 'Gb':9, 'G':10, 'G#':11, 'Ab':11}
	try:
		halfsteps = int(octave)*12 + conversions[letter] - 48
	except:
		print('invalid note')
		quit()
	return halfsteps

def getnote():
	if args.note:
		steps = halfsteps(args.note)
		frequency = 440 * pow(pow(2,1/12),steps)
		return(frequency)
	elif args.freq:
		return(args.freq)
	else:
		print('You should pick a --note or --freq')
		quit()

def generatepitches():
	pitches = [[],[],[],[],[],[],[]]	# Datastructure for all possible pitches above 15 Hz
	pitch = 56244
	index = 6
	while index > -1:
		divisor = 1
		while pitch/divisor > 15:
			pitches[index].append(pitch/divisor)
			divisor = divisor + 1
		pitch = pitch / 2
		index = index - 1
	return pitches

def closest(lst, K):
    return lst[min(range(len(lst)), key = lambda i: abs(lst[i]-K))]
      
frequency = getnote()
pitches = generatepitches()

# Do the thing
print("For {:.2f}:".format(frequency))
for div in range(7):
	for idx,pitch in enumerate(pitches[div]):
		if pitches[div][idx] > frequency and pitches[div][idx+1] < frequency:
			print("\tDiv {}: pitch {} ({:.2f}) - pitch {} ({:.2f})".format(div,idx+1,pitches[div][idx+1],idx,pitches[div][idx]))
			nearest = closest([pitches[div][idx],pitches[div][idx+1]],frequency)
			print('\t\tNearest: {:.2f} by {:.2f}%'.format(nearest,abs(((frequency-nearest)/frequency)*100)))
