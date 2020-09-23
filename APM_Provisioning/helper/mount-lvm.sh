#!/bin/bash -e

#
# Mounts the given device $1 to the given target $2 as logical volume using lvm2.
# This script will do nothing if a mount already exists at the given target.
#

DEVICE=$1
DEV=/dev/$DEVICE
TARGET=$2
OWNER=$3
FSTYPE=ext4
VOLUME_GROUP_NAME="${DEVICE}_vg1"
LOGICAL_VOLUME="/dev/${VOLUME_GROUP_NAME}/${DEVICE}"

if mount | grep "$TARGET" >/dev/null; then
  echo "Found existing mount for target $TARGET"
  # todo: raise (at least) a warning if mount exists but with a different device
  exit 0
fi

echo "No existing mount of $DEV found for $TARGET"

if [ -d "$TARGET" ]; then
  echo "Found existing folder for $TARGET"
else
  echo "Creating target folder $TARGET"
  mkdir -p "$TARGET"
fi

chown "${OWNER}:${OWNER}" "$TARGET" || true

if [ "$OWNER" == vcap ]; then
  chmod g+sw "$TARGET" || true
fi

if [ ! -b "$DEV" ]; then
  echo "ERROR: volume device $DEV not found or not a block device."
  exit 1
fi

# 1: intialize the device as an LVM physical volume if not yet done
if ! pvs "$DEV"; then
  echo "Initializing device $DEVICE as LVM physical volume"
  pvcreate "${DEV}"
else
  echo "Device $DEVICE already initialized as LVM physical volume"
fi

# 2: create an LVM volume group if not yet done
if ! pvs "$DEV" -o vg_name | grep "$VOLUME_GROUP_NAME"; then
  echo "Creating volume group $VOLUME_GROUP_NAME using block device $DEV"
  vgcreate "${VOLUME_GROUP_NAME}" "$DEV"
else
  echo "Volume group $VOLUME_GROUP_NAME already exists for block device $DEV"
fi

# 3: create the appropriate logical volume that uses all of the unallocated space within the volume group
if ! pvdisplay -m "$DEV" | grep "Logical volume" | grep "$LOGICAL_VOLUME"; then
  echo "Creating logical volume in volume group $VOLUME_GROUP_NAME"
  lvcreate -y -l 100%FREE -n "${DEVICE}" "${VOLUME_GROUP_NAME}"

  # only format file system if it hasn't been formatted
  # for safety-reasons we will do this only if logical volume was created just before
  if ! file --dereference -s "$LOGICAL_VOLUME" | grep "$FSTYPE"; then
    echo "Formatting logical volume $LOGICAL_VOLUME as $FSTYPE"
    mkfs -t "$FSTYPE" "$LOGICAL_VOLUME"  || { echo "cannot create filesystem">&2; exit 1; }
  else
    echo "Logical volume $LOGICAL_VOLUME already formatted"
  fi
else
  echo "logical volume ${LOGICAL_VOLUME} already exists"
fi

# manage fstab
if grep "${LOGICAL_VOLUME}" </etc/fstab >/dev/null; then
  echo "Found fstab entry"
else
  echo "Creating fstab entry"
  echo "${LOGICAL_VOLUME}         ${TARGET}   ${FSTYPE}   defaults  0 0" >> /etc/fstab
fi

echo "Mounting $TARGET"
mount "$TARGET" || { echo "cannot mount filesystem">&2; exit 1; }
chown "${OWNER}:${OWNER}" "$TARGET" || true

echo "Succesfully finished volume setup for device $DEVICE and target folder $TARGET"
