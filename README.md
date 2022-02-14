[Chinese Translation](https://github.com/OnlyTomInSecond/nvidia-xrun/blob/master/README_zh_CN.md)

# NOTICE #

### This is a fork from official nvidia-xrun repo , and I just did a minor changes and not tested yet.Only test nvidia-xrun-pm.service ###

### If the monitor output mode is iGPU(Using amdgpu),you can enable the nvidia-xrun-pm.service , but in dGPU mode you must disable it Otherwise the monitor will be black!!! ###

Here is the official tutorial, but I just adjusted a little .... :-)

# nvidia-xrun #
These utility scripts aim to make the life easier for nvidia cards users.It started with a revelation that bumblebee in current state offers very poor performance. This solution offers a bit more complicated procedure but offers a full GPU utilization(in terms of linux drivers)

## Usage: ##
  - switch to free tty
  - login
  - run `nvidia-xrun [app]`
  - enjoy

Currently sudo is required as the script needs to wake up GPU, modprobe the nvidia driver and perform cleanup afterwards.

The systemd service can be used to completely remove the card from the kernel device tree (so that it won't even show in `lspci` output), and this will prevent the nvidia module to be loaded, so that we can take advantage of the
kernel PM features to keep the card switched off.

The service can be enabled with this command:

```
# systemctl enable nvidia-xrun-pm
```

This service can't be **restarted** , to power off gpu ,just run


```
# systemctl start nvidia-xrun-pm.service
```

When the nvidia-xrun command is used, the device is added again to the tree so that the nvidia module can be loaded properly: nvidia-xrun will remove the device and enable PM again after the application terminates.

## Structure ##
* **nvidia-xrun** - uses following dir structure:
* **/usr/bin/nvidia-xrun** - the executable script (./nvidia-xrun)
* **/etc/X11/nvidia-xorg.conf** - the main X confing file (./nvidia-xorg.conf),if this config can't light up your screen , just use the nvidia-xrun.conf.full instead (copy it to /etc/X11/nvidia-xorg.conf ,override the initial one)
* **/etc/X11/xinit/nvidia-xinitrc** - xinitrc config file. Contains the setting of provider output source (./nvidia-xinitrc )
* **/etc/X11/xinit/nvidia-xinitrc.d** - custom xinitrc scripts directory (use `mkdir`)
* **/etc/X11/nvidia-xorg.conf.d** - custom X config directory (use `mkdir` )
* **/etc/systemd/system/nvidia-xrun-pm.service** systemd service (./nvidia-xrun-pm.service)
* **/etc/default/nvidia-xrun** - nvidia-xrun config file (./config/nvdia-xrun)
* **/usr/share/xsessions/nvidia-xrun-openbox.desktop** - xsession file for openbox (./launchers/nvidia-xrun-openbox.desktop)
* **/usr/share/xsessions/nvidia-xrun-plasma.desktop** - xsession file for plasma (./launchers/nvidia-xrun-plasma.desktop)
* **[OPTIONAL] $XDG_CONFIG_HOME/X11/nvidia-xinitrc** - user-level custom xinit script file. You can set your favourite window manager here for example




## Setting the right bus id ##
Usually the 1:0:0 bus is correct. If this is not your case(you can find out through lspci or bbswitch output mesages) you can create a conf script for example `nano /etc/X11/nvidia-xorg.conf.d/30-nvidia.conf` to set the proper bus id:

```
    Section "Device"
        Identifier "nvidia"
        Driver "nvidia"
        BusID "PCI:1:0:0"
    EndSection
```

You can use this command to get the bus id:

```
	lspci | grep -i nvidia | awk '{print $1}'
```


Note that this prints your bus id in hexadecimal, but the Xorg configuration
script requires that you provide it in decimal, so you'll need to covert it.
You can do this with bash:

    # In this example, my bus id is "3c"
    bash -c "echo $(( 16#3c ))"

if the output like `00:01.0` then you don't need to do the convert

use `lspci -tv` to see the pci controller and the pci device id,change `DEVICE_BUS_ID` or `AUDIO_DEVICE_BUS_ID` in `config/nvidia-xrun` if needed.

Also this way you can adjust some nvidia settings if you encounter issues: **[Optional]**

```
    Section "Screen"
        Identifier "nvidia"
        Device "nvidia"
        #  Option "AllowEmptyInitialConfiguration" "Yes"
        #  Option "UseDisplayDevice" "none"
    EndSection
```

In order to make power management features work properly, you need to make sure
that bus ids in `/etc/default/nvidia-xrun` are correctly set for both the
NVIDIA graphic card and the PCI express controller that hosts it. You should be
able to find both the ids in the output of `lshw`: the PCIe controller is
usually displayed right before the graphic card.

## Automatically run window manager
For convenience you can create `nano ~/.config/X11/nvidia-xinitrc` and put there your favourite window manager:

```
    if [ $# -gt 0 ]; then
        $*
    else
        openbox-session
    #   startkde
    fi
```

With this you do not need to specify the app and you can simply run:

```
    nvidia-xrun
```

## AUR Package ##
The Arch Linux User Repository package can be found [here](https://aur.archlinux.org/packages/nvidia-xrun/).

## COPR Repository for Enterprise Linux, Fedora, Mageia, and openSUSE ##
The RPM packages and repository details for all supported distributions can be found on the [ekultails/nvidia-xrun](https://copr.fedorainfracloud.org/coprs/ekultails/nvidia-xrun/) COPR overview page.

### Install (Enterprise Linux and Fedora) ###

```
sudo dnf copr enable ekultails/nvidia-xrun
sudo dnf install nvidia-xrun
```

## Troubleshooting ##
### Steam issues ###
Yes unfortunately running Steam directly with nvidia-xrun does not work well - I recommend to use some window manager like openbox.

### HiDPI issue ###
When using openbox on a HiDPI (i.e. 4k) display, everything could be so small that is difficult to read.
To fix, you can change the DPI settings in `~/.Xresources (~/.Xdefaults)` file by adding/changing `Xft.dpi` setting. For example :

```
Xft.dpi: 192
```

### `nouveau` driver conflict ###
`nouveau` driver should be automatically blacklisted by `nvidia` but in case it is not, `nvidia` might not get access to GPU. Then you need to manually blacklist `nouveau` following Arch wiki https://wiki.archlinux.org/index.php/kernel_modules#Blacklisting.

### avoid `nvidia` driver to load on boot ###
`nvidia` driver may load itself on boot, then `nvidia-xrun` will fail to start Xorg session.
To avoid that, you should blacklist it (see link above).
Also sometimes, blacklisting is not enough and you should use some hack to really avoid it to load.
For example, adding `install nvidia /bin/false` to `/etc/modprobe.d/nvidia.conf` will make every load to fail.
In that case, you should add `--ignore-install` to `modprobe` calls in `nvidia-xrun` script.



### Vulkan does not work ###

Check https://wiki.archlinux.org/index.php/Vulkan
* remove package vulkan-intel
* set VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

## Reference ##

- [How to get Nvidia-xRun on Debian](https://daniele.tech/2019/12/how-to-get-nvidia-xrun-on-debian/)

- [Debian wiki](https://wiki.debian.org/NvidiaGraphicsDrivers/NvidiaXrun)
