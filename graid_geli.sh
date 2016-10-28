#!/bin/sh

geli_pass="123"
raid_disk="ada0 ada1"

graid label intel raid raid1 $raid_disk
gpart create -s MBR raid/r0

gpart add -t freebsd -s 596m raid/r0
gpart add -t freebsd raid/r0

gpart set -a active -i1 raid/r0

dd if=/dev/random of=/tmp/r0s2.key count=1 bs=64
echo $geli_pass > /tmp/pass

geli init -b -J /tmp/pass -K /tmp/r0s2.key /dev/raid/r0s2 || exit
geli attach -j /tmp/pass -k /tmp/r0s2.key /dev/raid/r0s2 || exit

gpart create -s BSD raid/r0s1
gpart create -s BSD raid/r0s2.eli
gpart add -t freebsd-ufs raid/r0s2.eli

gpart bootcode -b /boot/mbr raid/r0
gpart bootcode -b /boot/boot raid/r0s1

glabel label rootfs raid/r0s2.elia
glabel label bootfs raid/r0s1

newfs /dev/raid/r0s2.elia

mount /dev/raid/r0s2.elia /mnt
cd /mnt

dhclient em0
fetch http://ftp5.ru.freebsd.org/pub/FreeBSD/releases/amd64/10.3-RELEASE/base.txz
fetch http://ftp5.ru.freebsd.org/pub/FreeBSD/releases/amd64/10.3-RELEASE/kernel.txz
tar -xpf base.txz
tar -xpf kernel.txz
cp /tmp/r0s2.key /mnt/boot/

newfs /dev/raid/r0s1

mkdir .boot
mount /dev/raid/r0s1 /mnt/.boot
mkdir .boot/boot

cp -rp boot .boot
rm -rf /mnt/boot
ln -s .boot/boot boot

/bin/cat << EOF > /mnt/boot/loader.conf
geom_eli_load="YES"
geom_label_load="YES"
vfs.root.mountfrom="ufs:label/rootfs"
geli_raid_keyfile0_load="YES"
geli_raid_keyfile0_type="raid/r0s2:geli_keyfile0"
geli_raid_keyfile0_name="/boot/r0s2.key"
EOF

/bin/cat << EOF > /mnt/etc/fstab
/dev/label/rootfs	/	ufs	rw	1	1
/dev/label/bootfs	/.boot	ufs	rw	1	1
EOF

echo "Done"
