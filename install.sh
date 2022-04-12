#!/bin/bash

echo "Start installtion"

NVIDIA_PCI_BUS_ID=0
NVIDIA_AUDIO_PCI_ID=0

function get_info(){
echo "Get the basic information:"
# The bus id of nvidia card
NVIDIA_PCI_BUS_ID=`lspci | grep -i vga | grep -i nvidia | cut -d ' ' -f 1`
echo "The NVIDIA GPU id : $NVIDIA_PCI_BUS_ID"
NVIDIA_AUDIO_PCI_ID=`lspci | grep -i nvidia | grep -i audio | cut -d ' ' -f 1`
echo "The NVIDIA Audio device id : $NVIDIA_AUDIO_PCI_ID"

if [ -n ${NVIDIA_PCI_BUS_ID} ];then
	echo "Found nvidia gpu"
	if [ -n ${NVIDIA_AUDIO_PCI_ID} ];then 
		echo "Found nvidia audio device"
	else 
		echo "No audio device"
	fi
else
	echo "Not found nvidia gpu,exiting"
	exit 1;
fi
}

function find_acpi_support(){
if [ ! -f /sys/bus/pci/devices/0000:${NVIDIA_PCI_BUS_ID}/remove ] ||
   [ ! -f /sys/bus/pci/devices/0000:${NVIDIA_AUDIO_PCI_ID}/remove ];then
	echo "Can't find /sys/bus/pci/devices/${NVIDIA_PCI_BUS_ID}/remove ! Please check the driver installtion or ACPI module installed and loaded rightly!"
	return 0;
else 
	echo "Find acpi support"
	return 1;
fi
}

function modify_pcie_address(){
	echo "try to auto config"
	#sed -i 's/.*DEVICE_BUS_ID.*/DEVICE_BUS_ID=0000:'${NVIDIA_PCI_BUS_ID}'/' ./config/nvidia-xrun
	#sed -i 's/.*AUDIO_DEVICE_BUS_ID.*/AUDIO_DEVICE_BUS_ID=0000:'${NVIDIA_AUDIO_PCI_ID}'/' ./config/nvidia-xrun

	sed -i '/DEVICE_BUS_ID/d' ./config/nvidia-xrun
	sed -i '/AUDIO_DEVICE_BUS_ID/d' ./config/nvidia-xrun
	sed -i '6aDEVICE_BUS_ID=0000:'${NVIDIA_PCI_BUS_ID}'' ./config/nvidia-xrun
	sed -i '7aAUDIO_DEVICE_BUS_ID=0000:'${NVIDIA_AUDIO_PCI_ID}'' ./config/nvidia-xrun
	echo "success"
}

function install(){
    if [ find_acpi_support ];then
#	echo "Try autoconfig"
#	modify_pcie_address
	echo "Now copy the files"
	sudo cp ./nvidia-xrun /usr/bin/
	sudo cp ./nvidia-xinitrc /etc/X11/xinit
	sudo mkdir /etc/X11/nvidia-xorg.conf.d
	sudo cp ./nvidia-xrun-pm.service /etc/systemd/system/
	sudo cp ./config/nvidia-xrun /etc/default/
	echo "Add module blacklist "
	sudo cp ./modules/nvidia-xrun_blacklist.conf /etc/modprobe.d/

	echo "update systemd-daemon"
	sudo systemctl deamon-reload
	echo "enable nvidia-xrun-pm.service"
	sudo systemctl enable nvidia-xrun-pm.service
	echo "Update initramfs"
	sudo mkinitcpio -P
	echo "Done"
    else
	echo "Failed!"
    fi
}

get_info
find_acpi_support
modify_pcie_address
install


