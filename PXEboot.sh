#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# required packages
apt-get update > /dev/null
apt-get -y install tftpd-hpa isc-dhcp-server syslinux nfs-kernel-server > /dev/null
echo turning on tftpd
echo RUN_DAEMON="yes" >> /etc/default/tftpd-hpa
service tftpd-hpa start
rm /etc/dhcp/dhcpd.conf && touch /etc/dhcp/dhcpd.conf
# setting up DHCP. If you change the subnet, make sure to change where it is used everywhere
echo setting up dhcp
cat >> /etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
option domain-name "home.local";
option domain-name-servers 10.10.1.10;
default-lease-time 86400;
max-lease-time 604800;
option time-offset -18000;
authoritative;
log-facility local7;
allow booting;
allow bootp;
subnet 10.10.1.0 netmask 255.255.255.0 {
        get-lease-hostnames on;
        use-host-decl-names on;
        range 10.10.1.100 10.10.1.200;
        option routers 10.10.1.1;
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.10.1.255;
        filename "pxelinux.0";
        next-server 10.10.1.10;
}
EOF
echo starting DHCP server. remember this may change your network settings
service isc-dhcp-server start 
#moving files to the right place
mkdir -p /var/lib/tftpboot/pxelinux.cfg
cp /usr/lib/syslinux/pxelinux.0 /var/lib/tftpboot
touch /var/lib/tftpboot/pxelinux.cfg/default
mkdir -p /srv/install 
mkdir -p /tmp/iso
rm /etc/exports && touch /etc/exports
# adding exports for NFS
cat >> /etc/exports << EOF
/srv/install                  10.10.1.0/24(ro,async,no_root_squash,no_subtree_check) 
EOF
#more NFS exporting 
echo setting up NFS
service nfs-kernel-server stop
exportfs -a
service nfs-kernel-server start
#making places to put ISO and files
mkdir -p /var/lib/tftpboot/{ubuntu,Edubuntu,ubuntugnome,kubuntu,lubuntu,mythubuntu,ubuntustudio}/{amd64,i386}
mkdir -p /srv/install/{ubuntu,Edubuntu,ubuntugnome,kubuntu,lubuntu,mythubuntu,ubuntustudio}/{amd64,i386}
mkdir -p /mnt/loop 
cp /usr/lib/syslinux/vesamenu.c32 /var/lib/tftpboot/
#PXE menu configuration
cat >> /var/lib/tftpboot/pxelinux.cfg/default << EOFE
DEFAULT vesamenu.c32 
TIMEOUT 600
ONTIMEOUT BootLocal
PROMPT 0
MENU INCLUDE pxelinux.cfg/pxe.conf
NOESCAPE 1
LABEL BootLocal
        localboot 0
        TEXT HELP
        Boot to local hard disk
        ENDTEXT
LABEL Ubuntu
        MENU LABEL Ubuntu
        KERNEL ubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntu/amd64 initrd=ubuntu/amd64/initrd.lz
LABEL Ubuntu32
	MENU LABEL Ubuntu32
        KERNEL ubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntu/i386 initrd=ubuntu/i386/initrd.lz
LABEL EdUbuntu
        MENU LABEL EdUbuntu
        KERNEL edubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/edubuntu/amd64 initrd=edubuntu/amd64/initrd.lz
LABEL EdUbuntu32
	MENU LABEL EdUbuntu32
        KERNEL edubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/edubuntu/i386 initrd=edubuntu/i386/initrd.lz
MENU END
EOFE
cat >> /var/lib/tftpboot/pxelinux.cfg/pxe.conf << EOFE 
MENU TITLE  PXE Server 
MENU BACKGROUND pxelinux.cfg/logo.png
NOESCAPE 1
ALLOWOPTIONS 1
PROMPT 0
menu width 80
menu rows 14
MENU TABMSGROW 24
MENU MARGIN 10
menu color border               30;44      #ffffffff #00000000 std
EOFE
cd /tmp/iso
echo downloading Ubuntu. This may take a while.
wget http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-desktop-amd64.iso -q
wget http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/edubuntu/releases/14.04.2/release/edubuntu-14.04-dvd-amd64.iso -q
wget http://cdimage.ubuntu.com/edubuntu/releases/14.04.2/release/edubuntu-14.04-dvd-i386.iso -q
#wget
#wget
#wget
#wget
#wget
#wget
#wget
#wget
#wget
#wget
mount -o loop -t iso9660 /tmp/iso/ubuntu-14.04.2-desktop-amd64.iso /mnt/loop
echo copying files. This may take a while
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/ubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/ubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/ubuntu-14.04.2-desktop-amd64.iso 
mount -o loop -t iso9660 /tmp/iso/ubuntu-14.04.2-desktop-i386.iso /mnt/loop
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntu/i386
cp -R /mnt/loop/* /srv/install/ubuntu/i386
cp -R /mnt/loop/.disk /srv/install/ubuntu/i386
umount /mnt/loop
rm -f /tmp/iso/ubuntu-14.04.2-desktop-i386.iso #remove ISOs when done
mount -o loop -t iso9660 /tmp/iso/edubuntu-14.04-dvd-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/edubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/edubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/edubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/edubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/edubuntu-14.04-dvd-amd64.iso
mount -o loop -t iso9660 /tmp/iso/edubuntu-14.04-dvd-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/edubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/edubuntu/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/edubuntu/i386
cp -R /mnt/loop/.disk /srv/install/edubuntu/i386 
umount /mnt/loop
rm -f /tmp/iso/edubuntu-14.04-dvd-i386.iso
touch /var/lib/tftpboot/ubuntu/Ubuntu.menu #possibly not needed anymore. Still here just in case
cat >> /var/lib/tftpboot/ubuntu/Ubuntu.menu << EOFE
LABEL 2
        MENU LABEL Ubuntu 14.04.2 LTS (64-bit)
        KERNEL ubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:/srv/install/ubuntu/amd64 initrd=ubuntu/amd64/initrd.lz
        TEXT HELP
        Boot Ubuntu 64-bit
        ENDTEXT
LABEL 1
        MENU LABEL Ubuntu 14.04.2 LTS (32-bit)
        KERNEL ubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:/srv/install/ubuntu/i386 initrd=ubuntu/i386/initrd.lz
        TEXT HELP
        Boot Ubuntu 32-bit
        ENDTEXT
EOFE
