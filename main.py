import socket
import struct
import vlc

p = vlc.MediaPlayer(r"file:///C:\Users\Robin\PycharmProjects\BeamNG\GasGasGas.mp3")
# Create UDP socket.
sock1 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Bind to BeamNG OutGauge.
sock1.bind(('127.0.0.1', 4444))

start = 0
fadeIn = 0
fadeOut = 0
p.audio_set_volume(0)
maxVol = 55
stopSong = False
minLength = 2500
driftThreshold = 6
while True:
    # Receive data.
    data = sock1.recv(120)

    if not data:
        break  # Lost connection

    # Unpack the data.
    outsim_pack = struct.unpack('I4sH2c10f2I3f16s16si', data) #Format Characters see: https://docs.python.org/3/library/struct.html

    #print("RPM: ", str(outsim_pack[6]))
    #print("WheelSlipL: ", str(outsim_pack[13]))


    if float(str(outsim_pack[13])) >= driftThreshold and float((outsim_pack[14])) >= driftThreshold:
        start = p.get_time()
        fadeOut = p.get_time()
        if fadeIn + 300 > p.get_time() and p.audio_get_volume() < maxVol:
            fadeIn = p.get_time()
            p.audio_set_volume(p.audio_get_volume() + 5)
        p.play()
        if p.get_position() >= 0.99:
            p.set_position(0)
            p.stop()


    elif float(str(outsim_pack[13])) < driftThreshold and float((outsim_pack[14])) < driftThreshold and p.get_time() > start + minLength:

        fadeIn = p.get_time()
        if fadeOut + minLength + 800 > p.get_time() and p.audio_get_volume() > 0:
            fadeOut = p.get_time()
            p.audio_set_volume(p.audio_get_volume() - 1)
        elif p.audio_get_volume() == 0 and stopSong is True:
            p.stop()

    print(p.audio_get_volume())
    #print(p.get_time())
    print(p.get_position())
# Release the socket.
sock1.close()
