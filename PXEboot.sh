#!/bin/bash
sudo su -
apt-get update
apt-get -y install tftpd-hpa isc-dhcp-server syslinux
echo RUN_DAEMON="yes" >> /etc/default/tftpd-hpa
service tftpd-hpa start
rm /etc/dhcp/dhcpd.conf && touch /etc/dhcp/dhcpd.conf
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
service isc-dhcp-server start 
mkdir -p /var/lib/tftpboot/pxelinux.cfg
cp /usr/lib/syslinux/pxelinux.0 /var/lib/tftpboot
touch /var/lib/tftpboot/pxelinux.cfg/default
mkdir /srv/install && mkdir /tmp/iso
rm /etc/exports && touch /etc/exports
cat >> /etc/exports << EOF
/srv/install                  10.10.1.0/24(ro,async,no_root_squash,no_subtree_check) 
EOF
service nfs-kernel-server stop
exportfs -a
service nfs-kernel-server start
mkdir -p /var/lib/tftpboot/{fedora,ubuntu}/{amd64,i386}
mkdir -p /srv/install/{fedora,ubuntu}/{amd64,i386}
mkdir -p /mnt/loop
cp /usr/lib/syslinux/vesamenu.c32 /var/lib/tftpboot/
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
MENU BEGIN Ubuntu
MENU TITLE Ubuntu 
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE Ubuntu/Ubuntu.menu
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
mount -o loop -t iso9660 /tmp/iso/ubuntu-14.04.2-desktop-amd64.iso /mnt/loop
echo copying files. This may take a while
cp /mnt/loop/casper/vmlinuz /var/lib/tftpboot/ubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntu/amd64
cp -R /mnt/loop/* /srv/install/ubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/ubuntu/amd64
umount /mnt/loop
rm -f /tmp/iso/ubuntu-14.04.2-desktop-amd64.iso 
mount -o loop -t iso9660 /tmp/iso/ubuntu-14.04.2-desktop-i386.iso /mnt/loop
cp /mnt/loop/casper/vmlinuz /var/lib/tftpboot/ubuntu/amd64
cp /mnt/loop/casper/initrd.lz /var/lib/tftpboot/ubuntu/amd64
cp -R /mnt/loop/* /srv/install/ubuntu/amd64
cp -R /mnt/loop/.disk /srv/install/ubuntu/amd64
umount /mnt/loop
rm -f /tmp/iso/ubuntu-14.04.2-desktop-i386.iso 
touch /var/lib/tftpboot/ubuntu/Ubuntu.menu
cat >> /var/lib/tftpboot/ubuntu/Ubuntu.menu << EOFE
LABEL 2
        MENU LABEL Ubuntu 14.04.2 LTS (64-bit)
        KERNEL ubuntu/amd64/vmlinuz
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:/srv/install/ubuntu/amd64 initrd=ubuntu/amd64/initrd.lz
        TEXT HELP
        Boot Ubuntu 64-bit
        ENDTEXT
LABEL 1
        MENU LABEL Ubuntu 14.04.2 LTS (32-bit)
        KERNEL ubuntu/i386/vmlinuz
        APPEND boot=casper netboot=nfs nfsroot=10.10.1.10:/srv/install/ubuntu/i386 initrd=ubuntu/i386/initrd.lz
        TEXT HELP
        Boot Ubuntu 32-bit
        ENDTEXT
EOFE
