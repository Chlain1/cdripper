import sys
import os
import time
import cdio, pycdio


def ejectDisk():
    if (tryDisk()):
        os.system("/usr/bin/eject -t /dev/cdrom")
        print("Opened CD-Tray")
        return True
    else:
        print("CD-Tray already opened or not Found")
        return False

 


def tryDisk():
    try:
        d = cdio.Device(driver_id=pycdio.DRIVER_UNKNOWN)
        drive_name = d.get_device()
    except IOError:
        return False
    else:
        return True
        


ejectDisk()