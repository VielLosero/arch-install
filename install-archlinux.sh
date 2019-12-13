#!/bin/bash

#Mi script de instalacion de arch

version="version 0.2"

#### Comandos utiles
#less install.txt --> leer fichero install
#lsblk --> ver particiones montadas
#fdisk -l --> ver discos
#ifinstall_config --> ver interficies de red
#dig archlinux.org --> comprobar conexion a internet
#cat .zsh_history > /mnt/home/mi_zsh_history_arch_install.txt

########################################
# Log file 
########################################
LOGFILE=${PWD}/install-archlinux-logfile.txt
DATE=$(date '+%F %H:%M:%S')
echo "----------------------------------" >> $LOGFILE
#echo "$DATE Running $0 with $@ arguments." >> $LOG_FILE
echo "$DATE Started $0" >> $LOGFILE
echo "----------------------------------" >> $LOGFILE
#echo "Runing $0 with $@ arguments."
#echo "Look at $LOG_FILE for more info."


RUN="[\e[1;33m**\e[00m] "
FAIL="[\e[1;31mfailed\e[00m] "
OK="[\e[1;32mok\e[00m] "


set_default_net(){
#net
DNS="8.8.8.8"
WIRED_DEV="ens3"
IP_ADDR="192.168.2.99"
SUBMASK="255.255.255.0"
GATEWAY="192.168.2.100"
}

set_default_keymap(){
#Default keymap
KEYMAP="es"
}

set_default_partition(){
#defaults disk/device
DISK="sda"
DISKSIZE="$(lsblk -lnp | grep disk | grep $DISK | awk '{print $4}')"
# we make a BIOS partition +1M in /dev/sda1 for bios boot free space to prevent overwrited by grub on gpt
BOOT="2"
BOOTSIZE="+500M"
ROOT="3"
#ROOTSIZE="+150G" 
ROOTSIZE="+$(($(lsblk -lnpb | grep disk | grep sda | awk '{print $4}')/1024/1024/1024*25/100))G" # 25%
# defaults leave home on root 
HOME_="4"
#HOMESIZE="770G"
HOMESIZE="+$(($(lsblk -lnpb | grep disk | grep sda | awk '{print $4}')/1024/1024/1024*74/100))G" # 74%
SWAP="5"
#SWAPSIZE="+9G" 
#SWAPSIZE="+$(($(lsblk -lnpb | grep disk | grep sda | awk '{print $4}')/1024/1024/1024*1/100))G"
SWAPSIZE="rest" # teh rest of the disk
}

set_default_chroot(){
# chroot
HOST_NAME="tux"
#ln -sf /usr/share/zoneinfo/europe/madrid /etc/localtime  #ln -sf /usr/share/zoneinfo/zone/subzone /etc/localtime
LOCALTIME="/usr/share/zoneinfo/europe/madrid"
# locale
LOCALE="es_ES.UTF-8"
LOCALETYPE="UTF-8"
# clock
CLOCK="utc"
}

test_net(){
clear
header
echo -e "$DATE \e[00;33mTesting network install_config.\e[00m" >> $LOGFILE && tail -1 $LOGFILE
if ping -c 1 -w 1 -q www.example.com > /dev/null ; then ping_="ok" && echo -e "$DATE Internet connection $OK" >> $LOGFILE && tail -1 $LOGFILE; else ping_="down" && echo -e "$DATE Internet connection $FAIL">>$LOGFILE && tail -1 $LOGFILE;fi 
}

net_menu(){
test_net	
clear
header
echo " "
echo " net status: $ping_"
echo " "
echo -e " interface = \e[00;33m${WIRED_DEV}\e[00m"
echo -e " ip = \e[00;33m${IP_ADDR}\e[00m netmask = \e[00;33m${SUBMASK}\e[00m"
echo -e " gateway = \e[00;33m${GATEWAY}\e[00m"
echo -e " dns = \e[00;33m${DNS}\e[00m"
echo " "
echo " [0] Set default"
echo " [1] Manual install_configuration"
echo " [2] Dhcp ${WIRED_DEV} "
echo " [3] Dhcp wifi "
echo " "
echo -e "\e[00;31m [q] Quit/Exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [0-3] or [q]: \e[00m"

read -r option
case "$option" in
	0)	set_default_net && load_net 
		net_menu
		;;
	1)	clear; header
		echo " "
		read -p "Device: " WIRED_DEV 
		read -p "IP Address: " IP_ADDR 
		read -p "Submask: " SUBMASK
		read -p "Gateway: " GATEWAY
		read -p "Dns: " DNS
		load_net 
		net_menu
		;;
	2)	pkill dhcpcd
		dhcpcd ${WIRED_DEV} 
		net_menu
		;;
	3)	pkill dhcpcd
		dhcpdc wlan0
		net_menu
		;;
	q)	return
		;;
	*)	net
		;;
esac
}


load_net(){
echo -e "$DATE \e[00;33mLoading network install_config.\e[00m" >> $LOGFILE && tail -1 $LOGFILE
result=0
echo "nameserver ${DNS}" > /etc/resolv.conf 
ip link set up ${WIRED_DEV} 2>>$LOGFILE
if [ $? -ne 0 ] ; then result=1 && return ; fi
ip addr flush dev ${WIRED_DEV} 2>>$LOGFILE
if [ $? -ne 0 ]; then result=1 && return ; fi
ip addr add ${IP_ADDR}/${SUBMASK} dev ${WIRED_DEV} 2>>$LOGFILE
if [ $? -ne 0 ]; then result=1 && return ; fi
ip route add default via ${GATEWAY} 2>>$LOGFILE
if [ $? -ne 0 ]; then result=1 && return ; fi
if [ $result -eq 1 ]; then echo -e "$DATE Network install_config $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
}



keymap_menu(){
clear
header
echo " "
echo -e "keymap = \e[00;33m$KEYMAP\e[00m"
echo " "
echo " [0] Set default"
echo -e " [1] Select or change keymap"
echo " "
echo -e "\e[00;31m [q] Quit/Exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [0-1] or [q]: \e[00m"

read -r option
case "$option" in
	0)	set_default_keymap && load_keymap 
		keymap_menu
		;;
	1)	select KEYMAP in "${keymap_list[@]}"; do
		if [ "$KEYMAP" != "" ] ;then load_keymap && keymap_menu && break ;else echo "please select a correct option number ...";fi
		done
		;;
	q)	return
		;;
	*)	keymap_menu
		;;
esac
}

load_keymap(){
echo -e "$DATE \e[00;33mLoading keymap install_config.\e[00m" >> $LOGFILE && tail -1 $LOGFILE
loadkeys ${KEYMAP}
if [ $? -ne 0 ]; then echo -e "$DATE Load keymap $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
}

declare -a keymap_list=("ansi-dvorak" "amiga-de" "amiga-us" "applkey" "atari-de" "atari-se" "atari-uk-falcon" "atari-us" "azerty" "backspace" "bashkir" "be-latin1" "bg-cp1251" "bg-cp855" "bg_bds-cp1251" "bg_bds-utf8" "bg_pho-cp1251" "bg_pho-utf8" "br-abnt" "br-abnt2" "br-latin1-abnt2" "br-latin1-us" "by" "by-cp1251" "bywin-cp1251" "cf" "colemak" "croat" "ctrl" "cz" "cz-cp1250" "cz-lat2" "cz-lat2-prog" "cz-qwertz" "cz-us-qwertz" "de" "de-latin1" "de-latin1-nodeadkeys" "de-mobii" "de_ch-latin1" "de_alt_utf-8" "defkeymap" "defkeymap_v1.0" "dk" "dk-latin1" "dvorak" "dvorak-ca-fr" "dvorak-es" "dvorak-fr" "dvorak-l" "dvorak-la" "dvorak-programmer" "dvorak-r" "dvorak-ru" "dvorak-sv-a1" "dvorak-sv-a5" "dvorak-uk" "emacs" "emacs2" "es" "es-cp850" "es-olpc" "et" "et-nodeadkeys" "euro" "euro1" "euro2" "fi" "fr" "fr-bepo" "fr-bepo-latin9" "fr-latin1" "fr-latin9" "fr-pc" "fr_ch" "fr_ch-latin1" "gr" "gr-pc" "hu" "hu101" "il" "il-heb" "il-phonetic" "is-latin1" "is-latin1-us" "it" "it-ibm" "it2" "jp106" "kazakh" "keypad" "ky_alt_sh-utf-8" "kyrgyz" "la-latin1" "lt" "lt.baltic" "lt.l4" "lv" "lv-tilde" "mac-be" "mac-de-latin1" "mac-de-latin1-nodeadkeys" "mac-de_ch" "mac-dk-latin1" "mac-dvorak" "mac-es" "mac-euro" "mac-euro2" "mac-fi-latin1" "mac-fr" "mac-fr_ch-latin1" "mac-it" "mac-pl" "mac-pt-latin1" "mac-se" "mac-template" "mac-uk" "mac-us" "mk" "mk-cp1251" "mk-utf" "mk0" "nl" "nl2" "no" "no-dvorak" "no-latin1" "pc110" "pl" "pl1" "pl2" "pl3" "pl4" "pt-latin1" "pt-latin9" "pt-olpc" "ro" "ro_std" "ro_win" "ru" "ru-cp1251" "ru-ms" "ru-yawerty" "ru1" "ru2" "ru3" "ru4" "ru_win" "ruwin_alt-cp1251" "ruwin_alt-koi8-r" "ruwin_alt-utf-8" "ruwin_alt_sh-utf-8" "ruwin_cplk-cp1251" "ruwin_cplk-koi8-r" "ruwin_cplk-utf-8" "ruwin_ct_sh-cp1251" "ruwin_ct_sh-koi8-r" "ruwin_ct_sh-utf-8" "ruwin_ctrl-cp1251" "ruwin_ctrl-koi8-r" "ruwin_ctrl-utf-8" "se-fi-ir209" "se-fi-lat6" "se-ir209" "se-lat6" "sg" "sg-latin1" "sg-latin1-lk450" "sk-prog-qwerty" "sk-prog-qwertz" "sk-qwerty" "sk-qwertz" "slovene" "sr-cy" "sun-pl" "sun-pl-altgraph" "sundvorak" "sunkeymap" "sunt4-es" "sunt4-fi-latin1" "sunt4-no-latin1" "sunt5-cz-us" "sunt5-de-latin1" "sunt5-es" "sunt5-fi-latin1" "sunt5-fr-latin1" "sunt5-ru" "sunt5-uk" "sunt5-us-cz" "sunt6-uk" "sv-latin1" "tj_alt-utf8" "tr_f-latin5" "tr_q-latin5" "tralt" "trf" "trf-fggiod" "trq" "ttwin_alt-utf-8" "ttwin_cplk-utf-8" "ttwin_ct_sh-utf-8" "ttwin_ctrl-utf-8" "ua" "ua-cp1251" "ua-utf" "ua-utf-ws" "ua-ws" "uk" "unicode" "us" "us-acentos" "wangbe" "wangbe2" "windowkeys");

partition_menu(){
clear
header
echo " "
echo " partition map: "
echo -e "  	disk/device to format = \e[00;33m$DISK\e[00m size \e[00;33m$DISKSIZE\e[00m "
echo -e "  	partition \e[00;33m$BOOT\e[00m /boot size \e[00;33m$BOOTSIZE\e[00m"
echo -e "  	partition \e[00;33m$ROOT\e[00m / size \e[00;33m$ROOTSIZE\e[00m"
echo -e "  	partition \e[00;33m$HOME_\e[00m /home size \e[00;33m$HOMESIZE\e[00m"
echo -e "  	partition \e[00;33m$SWAP\e[00m swap size \e[00;33m$SWAPSIZE\e[00m"
echo " "
echo " [0] Set default"
echo -e " [1] Select or change partition map"
echo -e " [2] Apply/format disk with partition map"
echo -e " [3] Show fdisk"
echo -e " [4] Mount file system"
echo -e " [5] Show lsblk"
echo -e " [6] Manual partition with fdisk"
echo " "
echo -e "\e[00;31m [q] Quit/Exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [0-6] or [q]: \e[00m"

read -r option
case "$option" in
	0)	set_default_partition && partition_menu	
		;;
	1)	clear; header
		read -p "Disk/Device: " DISK
		read -p "/boot partition number: " BOOT
		read -p "/boot partition size: " BOOTSIZE
		read -p "/root partition number: " ROOT
		read -p "/root partition size: " ROOTSIZE
		read -p "/home partition number: " HOME_
		read -p "/home partition size: " HOMESIZE
		read -p "swap partition number: " SWAP
		read -p "swap partition size: " SWAPSIZE
		partition_menu
		;;
	2)	erase_disk_warning
		partition_menu
		;;
		
	3)	echo "" && fdisk -l | grep /dev && echo -e "\n pres a key ...." ;read && partition_menu
		;;
	4)	clear
		header
		echo " "
		echo -e "$DATE\e[00;33m Mounting devices.\e[00m" >> $LOGFILE && tail -1 $LOGFILE
		disk_mount 
		#clear
		echo " "
		echo "$(lsblk)"
		echo " "
		echo -e "\e[00;31m disk ready to install system. pres a key to back partition menu  ...\e[00m"
		read
		partition_menu
		;;
	5)	echo "" && lsblk && echo -e "\n pres a key ...." ;read && partition_menu
		;;
	6)	read -p "\nEnter Disk/Device to format: " DISK && fdisk /dev/$DISK && partition_menu
		;;
	q)	return
		;;
	*)	partition_menu
		;;
esac
}


erase_disk_warning(){
clear
header
echo " "
echo " this will erase all the data on /dev/${DISK} "
echo " are you sure? yes or q"
echo " "
echo -e "\e[00;31m [q] quit/exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter [yes] or [q]: \e[00m"

read -r option
case "$option" in
	yes)	disk_format
		echo " "
		echo "$(lsblk -f)" 	
		echo " "
		echo -e "\e[00;31m pres a key to back partition menu ...\e[00m"
		read
		;;
	q)	return
		;;
	*)	erase_disk_warning
		;;
esac
}

disk_format(){
# if mounted
[ "$(ls -A /mnt)" ] && echo "Dir /mnt not empty, traying to umount filesystem" >> $LOGFILE && tail -1 $LOGFILE  && umount -R /mnt 
[ "$(ls -A /mnt)" ] && echo "Dir /mnt not empty, exiting " && exit 1
[ ! "$(ls -A /mnt)" ] && echo "$DATE Umount successfully, continue ... " >> $LOGFILE && tail -1 $LOGFILE 
echo -e "$DATE\e[00;33m Partitioning disk ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
echo -e "g\nn\n1\n\n+1M\nn\n${BOOT}\n\n${BOOTSIZE}\nn\n${ROOT}\n\n${ROOTSIZE}\nn\n${HOME_}\n\n${HOMESIZE}\nn\n${SWAP}\n\n\nt\n1\n4\nt\n2\n20\nt\n3\n19\nt\n4\n20\nw\n" | fdisk /dev/${DISK} 2>&1 >> $LOGFILE || exit 1 


#echo -e "g\nn\n1\n\n+1M\nn\n${BOOT}\n\n${BOOTSIZE}\nn\n${SWAP}\n\n${SWAPSIZE}\nn\n${ROOT}\n\n\nt\n1\n4\nt\n2\n20\nt\n3\n19\nt\n4\n20\nw\n" | fdisk /dev/${DISK}
#sed -e 's/\s*\([\+0-9a-za-z]*\).*/\1/' << fdisk_cmds  | sudo fdisk /dev/$1
#g      # create new gpt partition
#n      # add new partition
#1      # partition number
#       # default - first sector
#+1m    # partition size
#n      # add new partition
#2      # partition number
#       # default - first sector
#+500m  # default - last sector
#n      # add new partition
#3      # partition number
#       # default - first sector
#+9g    # default - last sector
#n      # add new partition
#4      # partition number
#       # default - first sector
#       # default - last sector
#t      # change partition type
#1      # partition number
#4      # bios boot
#t      # change partition type
#2      # partition number
#20     # linux filesystem change to vfat for uefi
#t      # change partition type
#3      # partition number
#19     # linux swap
#t      # change partition type
#4      # partition number
#20     # linux filesystem
#w      # write partition table and exit
#fdisk_cmds
echo -e "$DATE Disk partitions done. $OK" >> $LOGFILE && tail -1 $LOGFILE
	#clear
	#header
	#echo " "
	#echo "$(fdisk -l /dev/${DISK})"	
	#echo " "
	#echo -e "\e[00;31m disk formated, pres a key to make filesysem with XFS ...\e[00m"
	#read
	# make filesistems
	# tested with qemu-nbd and virtual machine, need to rethink what to do for diferent devices, change dev/sda1 for dev/nbd0p1.
	## bios boot +1m /dev/sda1 	 # <- bios boot free space to prevent overwrited by grub on gpt
echo -e "$DATE\e[00;33m Formating filesystem partitions ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
	echo " "
	echo -e "$DATE making filesystem for boot" >> $LOGFILE && tail -1 $LOGFILE
	mkfs.xfs -f -L BOOT /dev/${DISK}${BOOT} 2>&1 >> $LOGFILE || exit 1     # <- boot partition format vfat for uefi
	echo -e "$DATE making filesystem for swap" >> $LOGFILE && tail -1 $LOGFILE
	mkswap -f -L SWAP /dev/${DISK}${SWAP} 2>&1 >> $LOGFILE || exit 1     # <- swap partition
	echo -e "$DATE making filesystem for root" >> $LOGFILE && tail -1 $LOGFILE
	mkfs.xfs -f -L ROOT /dev/${DISK}${ROOT} 2>&1 >> $LOGFILE || exit 1    # <- root partition
	echo -e "$DATE making filesystem for home" >> $LOGFILE && tail -1 $LOGFILE
	mkfs.xfs -f -L HOME /dev/${DISK}${HOME_} 2>&1 >> $LOGFILE || exit 1     # <- home partition
	
echo -e "$DATE Partitions format done. $OK" >> $LOGFILE && tail -1 $LOGFILE
}

disk_mount(){
echo -e "$DATE\e[00;33m Mounting filesystem ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
# check if var not empty
[ -z $DISK ] && set_default_partition
#
# mounting devices
#echo " umounting if mounted"
[ "$(ls -A /mnt)" ] && echo "Dir /mnt not empty, traying to umount filesystem" >> $LOGFILE && tail -1 $LOGFILE  && umount -R /mnt 
[ "$(ls -A /mnt)" ] && echo "Dir /mnt not empty, exiting " && exit 1
[ ! "$(ls -A /mnt)" ] && echo "$DATE Umount successfully, continue ... " >> $LOGFILE && tail -1 $LOGFILE 
mount /dev/${DISK}${ROOT} /mnt || exit 1
mkdir /mnt/boot
mount /dev/${DISK}${BOOT} /mnt/boot || exit 1
mkdir /mnt/home
mount /dev/${DISK}${HOME_} /mnt/home || exit 1

#cryptsetup -v --type luks --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase luksformat /dev/sdax
#cryptsetup open /dev/sdax home
#mount /dev/mapper/home /mnt/
#pacman -Ss xfs
#pacman -S xfsdump xfsprogs
#mkfs.xfs /dev/mapper/home 
#mount /dev/mapper/home /home/
#echo "/dev/mapper/home      /home     xfs    defaults        0 0" >> /etc/fstab 
#echo "## <name>       <device>        <password>              <type?>" >> /etc/crypttab 
#echo "home	/dev/sdaX	0 0" >> /etc/crypttab 
echo -e "$DATE Filesystem mounted. $OK" >> $LOGFILE && tail -1 $LOGFILE
}


chroot_menu(){
clear
header
echo " "
echo -e " [7] Select or change Hostname = \e[00;33m${HOST_NAME}\e[00m" 
echo -e " [8] Select or change Localtime = \e[00;33m${LOCALTIME}\e[00m" 
echo -e " [8] Select or change Locales = \e[00;33m${LOCALE}\e[00m"
echo -e " [8] Select or change Locales = \e[00;33m${LOCALETYPE}\e[00m"
echo -e " [9] Select or change Clock = \e[00;33m${CLOCK}\e[00m"

echo -e "\e[00;31m [q] Quit/Exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [1-X] or [q]: \e[00m"

read -r option
case "$option" in
	1)	disk_selection
		;;
	2)	partition_selection
		;;
	q)	return
		;;
	*)	install_config_menu
		;;
esac
}


installation_menu(){
clear
header
echo " "
echo " [0] autoinstall"
echo " [1] update before install"
echo " [2] install base packages"
echo " [3] chroot and install_config system"
echo " [4] chroot and install grub"
echo " [5] chroot and change root passwd"
echo " [6] umount all and reboot"
echo " "
echo -e "\e[00;31m [q] quit/exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [1-6] or [q]: \e[00m"

read option
case "$option" in
	0)	update
		install_base
		install_config
		install_grub
		passwd_root
		umount -R /mnt && reboot now
		;;
	1)	update
		installation_menu
		;;
	2)	install_base
		installation_menu
		;;
	3)	install_config
		installation_menu
		;;
	4)	install_grub
		installation_menu
		;;
	5)	passwd_root
		installation_menu
		;;
	6)	umount -R /mnt && reboot now
		;;
	q)	return
		;;
	*)	installation_menu
		;;
esac
}


update(){
echo -e "$DATE\e[00;33m Updating keys and system ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
#pacman-key --refresh-keys && pacman -Syy 
pacman -Syy 
if [ $? -ne 0 ]; then echo -e "$DATE Update $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
}

install_base(){
echo -e "$DATE\e[00;33m Installing base system ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
[ ! "$(ls -A /mnt)" ] && echo "Dir /mnt empty, filesystem not mounted exiting... Install $FAIL" && exit 1
pacstrap /mnt base linux linux-firmware base-devel dhcpcd xfsprogs && genfstab -p /mnt > /mnt/etc/fstab && cp $0 /mnt/root
if [ $? -ne 0 ]; then echo -e "$DATE Install base $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
##copy script to root filesystem to install software inside chroot and after reboot
#cp $0 /mnt/root/
}

install_config(){
echo -e "$DATE\e[00;33m Installing config at chroot ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE
[ -z $KEYMAP ] && set_default_keymap
set_default_chroot
cat <<EOF> /mnt/root/install_config.sh
echo ${HOST_NAME} > /etc/hostname
ln -sf ${LOCALTIME} /etc/localtime  #ln -sf /usr/share/zoneinfo/zone/subzone /etc/localtime
echo > /etc/locale.conf
echo 'lang=${LOCALE}' >> /etc/locale.conf
echo 'lc_ctype="${LOCALE}"' >> /etc/locale.conf
echo 'lc_numeric="${LOCALE}"' >> /etc/locale.conf
echo 'lc_time="${LOCALE}"' >> /etc/locale.conf
echo 'lc_collate="${LOCALE}"' >> /etc/locale.conf
echo 'lc_monetary="${LOCALE}"' >> /etc/locale.conf
echo 'lc_messages="${LOCALE}"' >> /etc/locale.conf
echo 'lc_paper="${LOCALE}"' >> /etc/locale.conf
echo 'lc_name="${LOCALE}"' >> /etc/locale.conf
echo 'lc_address="${LOCALE}"' >> /etc/locale.confecho 
echo 'lc_telephone="${LOCALE}"' >> /etc/locale.conf
echo 'lc_measurement="${LOCALE}"' >> /etc/locale.conf
echo 'lc_identification="${LOCALE}"' >> /etc/locale.conf

cp /etc/locale.gen /etc/locale.gen.bkp
echo "${LOCALE} ${LOCALETYPE}" > /etc/locale.gen
locale-gen

#echo "clock=${CLOCK}" > /etc/conf.d/hwclock
hwclock --systohc
# mkinitcpio was run if linux kernel are installed with pacstrap
#mkinitcpio -p linux
echo "keymap=${KEYMAP}" > /etc/vconsole.conf
#localectl set-x11-keymap ${KEYMAP}
EOF

arch-chroot /mnt chmod 700 /root/install_config.sh
arch-chroot /mnt /root/install_config.sh
if [ $? -ne 0 ]; then echo -e "$DATE Install config $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
}

install_grub(){
echo -e "$DATE\e[00;33m Installing grub ....\e[00m" >> $LOGFILE && tail -1 $LOGFILE

arch-chroot /mnt pacman -S grub os-prober # efibootmgr
#arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
# efi-directory especifica el punto de montaje de la esp
# bootloader-id especifica el nombre del directorio utilizado para guardar el archivo grubx64.efi
# need to rethink for bios grub. seems auto if not efi.
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
arch-chroot /mnt grub-install --recheck /dev/${DISK}
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg 
if [ $? -ne 0 ]; then echo -e "$DATE Install grub failed $FAIL" >> $LOGFILE && tail -1 $LOGFILE && exit 1 ; fi
}

passwd_root(){
clear
header
echo " Enter root password for the new system ..."
arch-chroot /mnt passwd
}



#
extra_packages_menu(){
clear
header
echo " "
echo " "
echo " [0] install all"
echo " [1] install esentials"
echo " [2] install desktop"
echo " [3] install net"
echo " [4] install web"
echo " [5] install audio/video"
echo " [6] install office"
echo " [7] install virtualization"
echo " [8] install security"
echo " [9] install forensics"
echo " "
echo -e "\e[00;31m [q] quit/exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [1-9] or [q]: \e[00m"

read option
case "$option" in
	0)	esentials
		desktop
		net_install
		web
		audio_video
		office
		virtualization
		security
		forensics
		extra_packages_menu
		;;
	1)	esentials && extra_packages_menu
		;;
	2)	desktop && extra_packages_menu
		;;
	3)	net_install && extra_packages_menu
		;;
	4)	web && extra_packages_menu
		;;
	5)	audio_video && extra_packages_menu
		;;
	6)	office && extra_packages_menu
		;;
	7)	virtualization && extra_packages_menu
		;;
	8)	security && extra_packages_menu 
		;;
	9)	forensics $$ extra_packages_menu
		;;
	q)	return
		;;
	*)	extra_packages_menu
		;;
esac
}

# to list packages in one line
# pacman -qe | awk '{print $1}' | awk 'begin{rs="="} $1=$1'

esentials(){
# esentials
pacman -S archey3 cantarell-fonts htop iotop nano ncdu ranger rsync sudo sysstat tmux ttf-dejavu unzip vi vim wget xfsdump xfsprogs zsh lsof git lshw
}

desktop(){
# x desktop 
pacman -S i3-wm xorg-xinit xorg-server dmenu mesa-demos feh w3m termite
}

net_install(){
# net conectivity
pacman -S openssh openvpn bind-tools bridge-utils macchanger wpa_supplicant net-tools dnsmasq transmission-gtk
}

web(){
# web navigation
pacman -S firefox youtube-dl git 
}

audio_video(){
# audio and video
pacman -S audacity deadbeef flameshot handbrake handbrake-cli openshot sox alsa-utils pulseaudio pulseaudio-alsa mpv
}

office(){
# office, mail 
pacman -S klavaro claws-mail libreoffice-fresh-es 
}

virtualization(){
# virtualization
pacman -S libvirt qemu virt-manager 
}

security(){
# security
pacman -S keepassxc 
}

forensics(){
# forensic
pacman -S testdisk
}


post_install_menu(){	
clear
header
echo " "
echo " "
echo " [0] all"
echo " [1] default interface names"
echo " [2] hidden ipv6 mac address"
echo " [3] dont store coredumps with sensible info"
echo " [4] set umask read/write for owner only"
echo " [5] set delay after failed logins attemps"
echo " [6] set up iptables"
echo " [7] install harden kernel"
echo " [8] autostart x"
echo " [9] show links for info post install"
echo " "
echo -e "\e[00;31m [q] quit/exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [1-9] or [q]: \e[00m"

read option
case "$option" in
	0)	default_interface_names
		hidden_ipv6_mac 
		no_store_coredump 
		set_umask 
		delay_after_failed_logins
		iptables_install_config 
		harden_kernel
		autostartx
		post_install_menu
		;;
	1)	default_interface_names && post_install_menu
		;;
	2)	hidden_ipv6_mac && post_install_menu
		;;
	3)	no_store_coredump && post_install_menu
		;;
	4)	set_umask && post_install_menu
		;;
	5)	delay_after_failed_logins && post_install_menu
		;;
	6)	iptables_install_config && post_install_menu
		;;
	7)	harden_kernel && post_install_menu
		;;
	8)	autostartx && post_install_menu 
		;;
	9)	show_links
		;;
	q)	return
		;;
	*)	post_install_menu
		;;
esac
}


default_interface_names(){
##### set net interfaces name to eth0 and wlan0
#see --> http://www.freedesktop.org/wiki/software/systemd/predictablenetworkinterfacenames/
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
}

hidden_ipv6_mac(){
## enable ipv6 privacy extensions dont show mac on ipv6 address
echo "net.ipv6.conf.all.use_tempaddr = 2" > /etc/sysctl.d/40-ipv6.conf 
echo "net.ipv6.conf.default.use_tempaddr = 2" >> /etc/sysctl.d/40-ipv6.conf
echo "net.ipv6.conf.eth0.use_tempaddr = 2" >> /etc/sysctl.d/40-ipv6.conf
echo "net.ipv6.conf.wlan0.use_tempaddr = 2" >> /etc/sysctl.d/40-ipv6.conf
# need reboot
#etc... --> more interfaces
}


no_store_coredump(){
## prevent store coredumps with lot of info like passwords
echo "storage=none" >> /etc/systemd/coredump.conf
## prevent store coredumps with lot of info like passwords
echo "* hard core 0 " >> /etc/security/limits.conf
}


set_umask(){
#umasks set the default file permissions for newly created files. [40] the default is 022 which is not very secure. this gives read access to every user on the system for newly created files. edit /etc/profile and change the umask to 0077 which makes new files not readable by anyone other than the owner. 
#
#set to 0077
sed -i 's/umask 022/umask 0077/g' /etc/profile
}

delay_after_failed_logins(){

echo "auth optional pam_faildelay.so delay=4000000" >> /etc/pam.d/system-login
#4000000 is the time in microseconds to delay. 
}

harden_kernel(){
# install hardened kernel and reload grub
pacman -S linux-hardened
grub-mkinstall_config -o /boot/grub/grub.cfg
}

autostartx(){
##### start x at login
#add to ~/.bash_profile, use /etc/skel/.bash_profile template to create if not exist.
echo "[[ -z \$display && \$xdg_vtnr -eq 1 ]] && exec startx" >> ~/.bash_profile
echo "setxkbmap es" > ${home}/.xinitrc
echo "i3" >> ${home}/.xinitrc
}

show_links(){
clear
header
echo "for harden system read https://wiki.archlinux.org/index.php/security"
echo " "
echo " press a key to back menu ..."
read
post_install_menu
}


iptables_install_config(){

cat <<EOF> /etc/iptables/ip6tables.rules

EOF

cat <<EOF> /etc/iptables/iptables.rules

EOF
# cp /etc/eptables/simple_firewall.rules /etc/iptables/iptables.rules
# cp /etc/eptables/simple_firewall.rules /etc/iptables/ip6tables.rules
systemctl enable iptables
systemctl enable ip6tables
systemctl start iptables
systemctl start ip6tables
}


header(){
echo -e "\n---------------------------------------------------------" 
echo -e "\e[1;32m Viel arch linux install script\e[00m $version"
echo -e "---------------------------------------------------------" 
}
main_menu(){
clear # cealr screeen
header # show header
echo " "
echo " [0] autoinstall base system with default values"
echo " [1] keyboard"
echo " [2] set up net"
echo " [3] partition disk"
echo " [4] install base system"
echo " [5] install extra packages"
echo " [6] post install"
echo " "
echo -e "\e[00;31m [q] quit/exit\e[00m" 
echo " "
echo "=========================================================" 
echo -ne "\e[1;32m enter a option [1-7] or [q]: \e[00m"
read option # read option
case "$option" in # exec option
	0)	clear ; header ; echo " "
		echo "This will install arch with default values and  "
		read -p "erase the entire disk, are you sure? [YES/NO]: " CONTROL
		if [ "$CONTROL" != "YES" ] ; then echo "Exiting ... " && exit 0
		else
		clear ; header
		set_default_keymap && load_keymap && echo -e "$DATE Keymap set $OK" || echo -e "$DATE Load keymap $FAIL"
		set_default_net && load_net && test_net || exit 1
		set_default_partition && disk_format && disk_mount || exit 1
		install_base || exit 1
		install_config || exit 1
		install_grub || exot 1
		arch-chroot /mnt passwd
		umount -R /mnt && reboot now
		fi
		exit 1
		;;
	1)	keymap_menu
		;;
	2)	net_menu
		;;
	3)	partition_menu
		;;
	4)	installation_menu
		;;
	5)	extra_packages_menu
		;;
	6)	post_install_menu
		;;
	q)	echo " " && exit 0
		;;
	
	*)	main_menu
		;;

esac	
}

#Start loop
while :; 
do
main_menu # Show menu
echo " "

done
exit 0

