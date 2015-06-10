# copyright (c) Justin Keller, you may freeley distribute this software AS IS without any modifications, but the project in which it is used must be "open-source" and covered under the GPL or MIT license.
#if you would like to change the file, issue a pull request, and it may be approved
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
mkdir -p /var/lib/tftpboot/{ubuntu,edubuntu,ubuntugnome,kubuntu,lubuntu,mythubuntu,ubuntustudio,xubuntu}/{amd64,i386}
mkdir -p /srv/install/{ubuntu,edubuntu,ubuntugnome,kubuntu,lubuntu,mythubuntu,ubuntustudio,xubuntu}/{amd64,i386}
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
LABEL UbuntuGnome
        MENU LABEL UbuntuGnome
        KERNEL ubuntugnome/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntugnome/amd64 initrd=ubuntugnome/amd64/initrd.lz
LABEL UbuntuGnome32
        MENU LABEL UbuntuGnome32
        KERNEL ubuntugnome/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntugnome/i386 initrd=ubuntugnome/1386/initrd.lz
LABEL MythBuntu
        MENU LABEL MythBuntu
        KERNEL mythubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/mythubuntu/amd64 initrd=mythubuntu/amd64/initrd.lz
LABEL MythBuntu32
        MENU LABEL MythBuntu32
        KERNEL mythubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/mythubuntu/i386 initrd=mythubuntu/1386/initrd.lz
 LABEL UbuntuStudio
        MENU LABEL UbuntuStudio
        KERNEL ubuntustudio/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntustudio/amd64 initrd=ubuntustudio/amd64/initrd.lz
LABEL UbuntuStudio32
        MENU LABEL UbuntuStudio32
        KERNEL ubuntustudio/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/ubuntustudio/i386 initrd=ubuntustudio/1386/initrd.lz
LABEL Lubuntu
        MENU LABEL Lubuntu
        KERNEL lubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/lubuntu/amd64 initrd=lubuntu/amd64/initrd.lz
LABEL Lubuntu32
        MENU LABEL Lubuntu32
        KERNEL lubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/lubuntu/i386 initrd=lubuntu/1386/initrd.lz
LABEL Xubuntu
        MENU LABEL Xubuntu
        KERNEL xubuntu/amd64/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/xubuntu/amd64 initrd=xubuntu/amd64/initrd.lz
LABEL Xubuntu32
        MENU LABEL Xubuntu32
        KERNEL xubuntu/i386/vmlinuz.efi
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:srv/install/xubuntu/i386 initrd=xubuntu/1386/initrd.lz
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
echo "downloading Ubuntu (all of them). This may take a while."
wget http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-desktop-amd64.iso -q
wget http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/edubuntu/releases/14.04.2/release/edubuntu-14.04-dvd-amd64.iso -q
wget http://cdimage.ubuntu.com/edubuntu/releases/14.04.2/release/edubuntu-14.04-dvd-i386.iso -q
wget http://cdimage.ubuntu.com/ubuntu-gnome/releases/14.10/release/ubuntu-gnome-14.10-desktop-amd64.iso -q
wget http://cdimage.ubuntu.com/ubuntu-gnome/releases/14.10/release/ubuntu-gnome-14.10-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/mythbuntu/releases/14.04.2/release/mythbuntu-14.04.2-desktop-amd64.iso -q
wget http://cdimage.ubuntu.com/mythbuntu/releases/14.04.2/release/mythbuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/ubuntustudio/releases/trusty/release/ubuntustudio-14.04-dvd-amd64.iso -q 
wget http://cdimage.ubuntu.com/ubuntustudio/releases/trusty/release/ubuntustudio-14.04-dvd-i386.iso -q
wget http://cdimage.ubuntu.com/lubuntu/releases/14.04/release/lubuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/lubuntu/releases/14.04/release/lubuntu-14.04.2-desktop-amd64.iso -q
wget http://cdimage.ubuntu.com/kubuntu/releases/trusty/release/kubuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/kubuntu/releases/trusty/release/kubuntu-14.04.2-desktop-amd64.iso -q
wget http://cdimage.ubuntu.com/xubuntu/releases/trusty/release/xubuntu-14.04.2-desktop-i386.iso -q
wget http://cdimage.ubuntu.com/xubuntu/releases/trusty/release/xubuntu-14.04.2-desktop-amd64.iso -q
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
mount -o loop -t iso9660 /tmp/iso/mythbuntu-14.04.2-desktop-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/mythubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/mythubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/mythubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/mythubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/mythbuntu-14.04.2-desktop-amd64.iso
mount -o loop -t iso9660 /tmp/iso/ubuntu-gnome-14.10-desktop-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntugnome/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntugnome/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/ubuntugnome/amd64
cp -R /mnt/loop/.disk /srv/install/ubuntugnome/amd64 
umount /mnt/loop
rm -f /tmp/iso/edubuntu-14.04-dvd-amd64.iso
mount -o loop -t iso9660 /tmp/iso/ubuntu-gnome-14.10-desktop-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntugnome/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntugnome/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/ubuntugnome/i386
cp -R /mnt/loop/.disk /srv/install/ubuntugnome/i386 
umount /mnt/loop
rm -f /tmp/iso/ubuntu-gnome-14.10-desktop-i386.iso
mount -o loop -t iso9660 /tmp/iso/mythbuntu-14.04.2-desktop-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/mythubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/mythubuntu/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/mythubuntu/i386
cp -R /mnt/loop/.disk /srv/install/mythubuntu/i386 
umount /mnt/loop
rm -f /tmp/iso/mythbuntu-14.04.2-desktop-i386.iso
mount -o loop -t iso9660 /tmp/iso/ubuntustudio-14.04-dvd-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntustudio/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntustudio/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/ubuntustudio/amd64
cp -R /mnt/loop/.disk /srv/install/ubuntustudio/amd64 
umount /mnt/loop
rm -f /tmp/iso/ubuntustudio-14.04-dvd-amd64.iso
mount -o loop -t iso9660 /tmp/iso/ubuntustudio-14.04-dvd-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/ubuntustudio/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntustudio/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/ubuntustudio/i386
cp -R /mnt/loop/.disk /srv/install/ubuntustudio/i386 
umount /mnt/loop
rm -f /tmp/iso/ubuntustudio-14.04-dvd-i386.iso
mount -o loop -t iso9660 /tmp/iso/lubuntu-14.04.2-desktop-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/lubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/lubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/lubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/lubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/lubuntu-14.04.2-desktop-amd64.iso
mount -o loop -t iso9660 /tmp/iso/lubuntu-14.04.2-desktop-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/lubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/lubuntu/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/lubuntu/i386
cp -R /mnt/loop/.disk /srv/install/lubuntu/i386 
umount /mnt/loop
rm -f /tmp/iso/lubuntu-14.04.2-desktop-i386.iso
mount -o loop -t iso9660 /tmp/iso/kubuntu-14.04.2-desktop-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/kubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/kubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/kubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/kubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/kubuntu-14.04.2-desktop-amd64.iso
mount -o loop -t iso9660 /tmp/iso/kubuntu-14.04.2-desktop-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/kubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/kubuntu/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/kubuntu/i386
cp -R /mnt/loop/.disk /srv/install/kubuntu/i386 
umount /mnt/loop
rm -f /tmp/iso/kubuntu-14.04.2-desktop-i386.iso
mount -o loop -t iso9660 /tmp/iso/xubuntu-14.04.2-desktop-amd64.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/xubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/xubuntu/amd64
#copying files for use by
cp -R /mnt/loop/* /srv/install/xubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/xubuntu/amd64 
umount /mnt/loop
rm -f /tmp/iso/xubuntu-14.04.2-desktop-amd64.iso
mount -o loop -t iso9660 /tmp/iso/xubuntu-14.04.2-desktop-i386.iso /mnt/loop
#copying nessicary files to boot
cp /mnt/loop/casper/vmlinuz.efi /var/lib/tftpboot/xubuntu/i386
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/xubuntu/i386
#copying files for use by
cp -R /mnt/loop/* /srv/install/xubuntu/i386
cp -R /mnt/loop/.disk /srv/install/xubuntu/i386 
umount /mnt/loop
rm -f /tmp/iso/xubuntu-14.04.2-desktop-i386.iso
touch /var/lib/tftpboot/ubuntu/Ubuntu.menu #possibly not needed anymore. Still here just in case
