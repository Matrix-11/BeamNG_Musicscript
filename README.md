# BeamNG_Musicscirpt
Play Music based on your driving in BeamNG

Tested for BeamNG.drive 0.24.1.2
Python 3.9

How it works:

This script uses BeamNGs outgauge support (normally used to integrate physical gauges with BeamNG)
to recieve ingame data via pythons socket libary.
I used "Angelo234"'s code from https://www.beamng.com/threads/outgauge-support-specifications.82507/ as basis

What gamedata is sent is specified in the outgauge.lua file under ...\steamapps\common\BeamNG.drive\lua\vehicle\extensions
To detect drifting I used BeamNGs 'wheelslip' variable (0 = perfekt traction, higher more slipping)
Following command returns the wheelslip value of the rearleft wheel:
'wheels.wheelRotators[2].lastSlip'

Installation:

Settings:
