import socket
import struct
import vlc
import time
from configparser import ConfigParser

config = ConfigParser()
config.read('config.ini')
settings = config['Settings']

p = vlc.MediaPlayer(r"file:///" + settings['filepath'])

start = 0
fadeIn = 0
fadeOut = 0
fadeInTime = settings.getint('fadeintime')
fadeOutTime = settings.getint('fadeouttime')
maxVol = settings.getint('maxvolume')
stopSong = settings.getboolean('stopSong')
minLength = settings.getint('minplaylength')
driftThreshold = settings.getfloat('driftthreshold')
debug = settings.getboolean('debug')

sock1 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create UDP socket.
sock1.settimeout(settings.getint('timeout'))  # Set timeout time in sec
sock1.bind((settings['outgaugeip'], settings.getint('outgaugeport')))  # Bind to BeamNG OutGauge.

p.audio_set_volume(0)

print("Waiting for UDP data")
while True:
    # Receive data.
    try:
        data = sock1.recv(120)
    except socket.timeout:
        print("UDP socket timed out :(")
        print("If this happens regularly maybe increase timeout in config")
        print("Bye...")
        time.sleep(3)
        break

    # Unpack the data.
    outsim_pack = struct.unpack('I4sH2c10f2I3f16s16si', data)  # Format Characters see: https://docs.python.org/3/library/struct.html

    if float(str(outsim_pack[13])) >= driftThreshold and float((outsim_pack[14])) >= driftThreshold:
        start = p.get_time()
        fadeOut = p.get_time()
        p.play()
        if fadeIn + fadeInTime > p.get_time() and p.audio_get_volume() < maxVol:
            fadeIn = p.get_time()
            p.audio_set_volume(p.audio_get_volume() + 5)

    elif float(str(outsim_pack[13])) < driftThreshold and float((outsim_pack[14])) < driftThreshold and p.get_time() > start + minLength:

        fadeIn = p.get_time()
        if fadeOut + minLength + fadeOutTime > p.get_time() and p.audio_get_volume() > 0:
            fadeOut = p.get_time()
            p.audio_set_volume(p.audio_get_volume() - 1)
        elif p.audio_get_volume() == 0 and stopSong is True:
            p.stop()

    if p.get_position() >= 0.95:
        p.set_position(0)
        p.stop()

    if debug:
        print(f"Song position: {p.get_position()}")
        print(f"Wheelsilp RL: {str(outsim_pack[13])}")
        print(f"Wheelsilp RR: {str(outsim_pack[14])}")

    print(f"Volume: {p.audio_get_volume()}")
    time.sleep(settings.getfloat('refreshrate'))
