# BeamNG_Musicscirpt
Play Music based on your driving in BeamNG

Tested for BeamNG.drive 0.24.1.2
Python 3.9

If someone wants to make a real BeamNG mod out of it feel free to do it!

This script can break if the BeamNG.drive devs change the lua commands or the outgauge.lua file is updated/changed

Please beware this is my first public project...

## How it works:

This script uses BeamNGs outgauge support (normally used to integrate physical gauges with BeamNG)
to recieve ingame data via pythons socket libary.
The data is recieved as struct and then unpacked.
If the wheelslip of the left- and rightrear wheel is over the set value the given audio file is played via the vlclib python libary.
I used "Angelo234"'s code from https://www.beamng.com/threads/outgauge-support-specifications.82507/ as basis

What gamedata is sent is specified in the outgauge.lua file under `...\steamapps\common\BeamNG.drive\lua\vehicle\extensions`
To detect drifting I used BeamNGs `wheelslip` variable (0 = perfect traction, higher more slipping).

Following command returns the wheelslip value of the rearleft wheel:
`wheels.wheelRotators[2].lastSlip`

`wheelRotators[]` returns wheelID of the given number e.g. 0-3 for a car with 4 wheels.
what data can be streamed is more or less documented under https://wiki.beamng.com/Streams but the website is outdated and contains errors.
So some try and error in the ingame lua console maybe required.

Settings are saved and modified in the config.ini file.

## Installation (Win10):

Requirements:
- ...BeamNG.drive
- Python 3
- VLC MediaPlayer

Either clone the repo via an IDE (better for troubleshooting) or execute the script in cmd (here explained)

Download the repo as zip and unzip it.
Go to `...\steamapps\common\BeamNG.drive\lua\vehicle\extensions` and replace the outgauge.lua file with the outgauge.lua file in the repo.

Open the config.ini via a editor and insert the filepath to your desired mp3 file.
Example: C:\Users\Usr\Desktop\TokyoDrift.mp3

Open cmd and navigate to the unzipped folder.
Install the required packages using:
`pip install -r requirements.txt`

Start BeamNG and turn on Outgauge Support in the settings.
The default ip: 127.0.0.1 port: 4444
Then load into a session.

Run `main.py` in the folder via cmd using:
`python main.py`

The programm should output the current volume and start playing the mp3 once you drift
(When the programm detects drifting changes depending on the vehicle)

Settings are explained in the config.ini

## Troubleshooting

- Make sure you have python 3 and VLC Mediaplayer installed. Both 32/64bit according to your system

- Program running, Volume increasing but no song playing: 
Double check the path to your mp3 file

- UDP Socket timeout:
IP adress and Port number have to match in config.ini and BeamNG options

- Timeout while lag/new vehicle loading:
Increase `timeouttime` in config.ini

- Song not looping:
In order to loop the song the programm checks the songs progress (float 0-1)
Often the song never gets to 1 so the programm loops when the song is at the `loopwhenat` variable specefied in the config.ini
So try to decrease the `loopwhenat` varible in the config.ini

