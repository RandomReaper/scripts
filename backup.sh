#!/bin/sh
#############################################################################
#
# Backup script (from disk to a removable drive)
#
# Author : marc@pignat.org
#
# Gloal : backup all files from the server to an external disk
#
# Remarks : Don't change the RSYNC_FLAGS unless you know what you're doing
#
#############################################################################

#############################################################################
# Sources and destination
#
#
# DESTINATION_PARTITION -> External disk partition
# Use /dev/disk/by-path or by-id to make sure which disk is used
#
DESTINATION_PARTITION="/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:0:0-part1"

#
# DESTINATION_DIR -> Mount destination
#
DESTINATION_DIR="/mnt/backup"

#
# SOURCE_DIRS -> List of source directories
# rsync will stay in one file system, so for a complete backup
# SOURCE_DIRS will be the list of the mount points
#
SOURCE_DIRS="/ /srv"

#############################################################################

#############################################################################
# SIM -> Do something before the real command
# example : SIM="echo" will only show the commands, with no execution
SIM=""
#############################################################################

#############################################################################
# RSYNC_FLAGS -> Flags used by rsync for xfer
#
# Make sure rsync don't cross file system boundaries
RSYNC_FLAGS="--one-file-system"

# Recursive, permission, links, ... MUST be managed
RSYNC_FLAGS="$RSYNC_FLAGS --archive"

# The files that need to be deleted should be deletet before xfer
# (useful when the destination is tight in space)
RSYNC_FLAGS="$RSYNC_FLAGS --delete-before"


# Backuppc uses hardlinks, so don't fill the destination disk
# with real files...
RSYNC_FLAGS="$RSYNC_FLAGS --hard-links"

# Optimize sparse files
RSYNC_FLAGS="$RSYNC_FLAGS --sparse"

# Now ignore those path..
RSYNC_FLAGS="$RSYNC_FLAGS --exclude=/tmp/"
RSYNC_FLAGS="$RSYNC_FLAGS --exclude=/var/lib/nagios3/spool/checkresults/"

#RSYNC_FLAGS="$RSYNC_FLAGS --verbose"

#############################################################################

$SIM echo "Backup start : $(date '+%F %T')"
$SIM mkdir -p $DESTINATION_DIR
$SIM mount -o noatime $DESTINATION_PARTITION $DESTINATION_DIR || exit 1

for SRC in $SOURCE_DIRS
do
	$SIM echo backup $SRC
	$SIM mkdir -p "$DESTINATION_DIR$SRC"
	$SIM rsync $RSYNC_FLAGS "$SRC" "$DESTINATION_DIR"
done
$SIM df -h $DESTINATION_DIR
$SIM umount $DESTINATION_DIR

$SIM echo "Backup end : $(date '+%F %T')"
