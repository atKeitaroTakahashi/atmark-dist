#!/bin/sh

. /etc/init.d/functions

PATH=/bin:/sbin:/usr/bin:/usr/sbin

create_flash_node() {
    mkdir -p /dev/flash
    for i in `grep mtd /proc/mtd | sed -e "s/ .* //" -e "s/[:,\"]/ /g"`
    do
    	if [ "mtd" = "${i%%[0-9]}" ]; then
	    node="$i"
	else
	    ln -fs /dev/$node /dev/flash/$i
	    ln -fs /dev/$node /dev/flash/`echo $i | sed "s/^nor.//"`
	fi
    done
}

# we need to unmount /dev/pts/ and remount it later over the tmpfs
unmount_devpts() {
  if mountpoint -q /dev/pts/; then
    umount -n -l /dev/pts/
  fi

  if mountpoint -q /dev/shm/; then
    umount -n -l /dev/shm/
  fi
}

# mount a tmpfs over /dev, if somebody did not already do it
mount_tmpfs() {
  if grep -E -q "^[^[:space:]]+ /dev (dev)?tmpfs" /proc/mounts; then
    mount -n -o remount,${dev_mount_options} -t tmpfs tmpfs /dev
    return
  fi

  mount -n -o $dev_mount_options -t tmpfs tmpfs /dev
  return
}

create_dev_makedev() {
  if [ -e /sbin/MAKEDEV ]; then
    ln -sf /sbin/MAKEDEV /dev/MAKEDEV
  else
    ln -sf /bin/true /dev/MAKEDEV
  fi
}

# If the initramfs does not have /run, the initramfs udev database must
# be migrated from /dev/.udev/ to /run/udev/.
move_udev_database() {
  [ -e "$udev_root/.udev/" ] || return 0
  [ ! -e /run/udev/ ] || return 0
  [ -e /run/ ] || return 0
  mountpoint -q /run/ || return 0

  mv $udev_root/.udev/ /run/udev/ || true
}

##############################################################################

[ -x /sbin/udevd ] || exit 0

PATH="/sbin:/bin"

# defaults
#tmpfs_size="10M"
udev_root="/dev"

if [ -e /etc/udev/udev.conf ]; then
  . /etc/udev/udev.conf
fi

##############################################################################

udev_root=${udev_root%/}

dev_mount_options='mode=0755'
if [ "$tmpfs_size" ]; then
  dev_mount_options="size=${tmpfs_size},${dev_mount_options}"
fi

if mountpoint -q $udev_root/; then
  TMPFS_MOUNTED=1
fi

echo > /sys/kernel/uevent_helper

move_udev_database

if [ -z "$TMPFS_MOUNTED" ]; then
  unmount_devpts
  mount_tmpfs
  [ -d /proc/1 ] || mount -n /proc
fi

# clean up parts of the database created by the initramfs udev
udevadm info --cleanup-db

# /dev/null must be created before udevd is started
/lib/udev/create_static_nodes || true

echo -n "Starting udevd:"
udevd --daemon
check_status

/lib/udev/write_dev_root_rule

echo -n "Synthesizing the initial hotplug events:"
udevadm trigger --action=add
check_status

create_dev_makedev

# wait for the udevd childs to finish
#echo -n "Waiting for /dev to be fully populated"
#udevadm settle
#check_status

create_flash_node
