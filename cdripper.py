import sys
import os
import time
import cdio, pycdio


def ejectDisk():
    try:
        d = cdio.Device(driver_id=pycdio.DRIVER_UNKNOWN)
        drive_name = d.get_device()
    except IOError:
        print("CD-Tray not found or open")
        sys.exit(1)

    os.system("/usr/bin/eject -t /dev/cdrom")
    print("Opened CD-Tray")
    return True


def tryDisk():
    try:
        d = cdio.Device(driver_id=pycdio.DRIVER_UNKNOWN)
        drive_name = d.get_device()
    except IOError:
        return False
    else:
        return True
        


