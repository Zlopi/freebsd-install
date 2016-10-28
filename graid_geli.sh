#!/bin/sh

graid delete raid/r0
graid label intel raid raid1 ada0 ada1
gpart destroy -F raid/r0
gpart create -s MBR raid/r0

gpart add -t freebsd -s 596m raid/r0
gpart add -t freebsd raid/r0

dd if=/dev/random of=/tmp/r0s2.key count=1 bs=64
echo "Geli Init"
geli init -b -K /mnt/boot/r0s2.key /dev/raid/r0s2
echo "Geli Attach"
geli attach -k /mnt/boot/r0s2.key /dev/raid/r0s2

gpart create -s BSD raid/r0s1
gpart create -s BSD raid/r0s2.eli
gpart add -t freebsd-ufs  raid/r0s1
gpart add -t freebsd-ufs raid/r0s2.eli

newfs /dev/raid/r0s1a
newfs /dev/raid/r0s2.elia

mount /dev/raid/r0s2.elia /mnt
mkdir /mnt/.boot
mount /dev/raid/r0s1a /mnt/.boot
mkdir .boot/boot
cd /mnt && ln -s .boot/boot boot
cp /tmp/r0s2.key /mnt/boot/

echo "Done"
