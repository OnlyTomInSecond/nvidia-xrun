#!/bin/sh

echo "Start installtion"

function get_info(){
echo "Get the basic information:"
# The bus id of nvidia card
NVIDIA_PCI_BUS_ID=`lspci | grep -i vga | grep -i nvidia | cut -d ' ' -f 1`
# echo "The NVIDIA GPU id : $NVIDIA_PCI_BUS_ID"
NVIDIA_AUDIO_PCI_ID=`lspci | grep -i nvidia | grep -i audio | cut -d ' ' -f 1`
echo "The NVIDIA Audio device id : $NVIDIA_AUDIO_PCI_ID"
if [ -z "${NVIDIA_PCI_BUS_ID}" ];then
	echo "Found nvidia card"
	if [ -z "${NVIDIA_AUDIO_PCI_ID}" ];then
		echo "Found nvidia audio device"
else
	echo "Error,Can;t find nvidia card! Exiting"
	exit 0
fi
}

if [ ! -f /sys/bus/pci/devices/0000:${NVIDIA_PCI_BUS_ID}/remove ] ||
   [ ! -f /sys/bus/pci/devices/0000:${NVIDIA_AUDIO_PCI_ID}/remove ];then
	echo "Can't find /sys/bus/pci/devices/${NVIDIA_PCI_BUS_ID}/remove ! Please check the driver installtion or ACPI module installed and loaded rightly!"
	exit 0
fi

echo "Now copy the files"
sudo cp ./nvidia-xrun /usr/bin/
sudo cp ./nvidia-xinitrc /etc/X11/xinit
mkdir /etc/X11/nvidia-xorg.conf.d
sudo cp ./nvidia-xrun-pm.service /etc/systemd/system/
sudo cp ./config/nvidia-xrun /etc/default/

echo "update systemd-daemon"
sudo systemctl deamon-reload
echo "enable nvidia-xrun-pm.service"
sudo systemctl enable nvidia-xrun-pm.service
