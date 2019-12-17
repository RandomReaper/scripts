#!/bin/bash
#############################################################################
#
# \brief Backup to a local disk (from a mounted partition or a remote ssh host)
#
# \warning Don't change the RSYNC_FLAGS unless you know what you're doing ;)
#
# \url https://github.com/RandomReaper/scripts
#
# Copyright (c) 2017-2019 Marc Pignat
# SPDX-License-Identifier: 	Apache-2.0
# License-Filename: LICENSE
#
# \env SIM when set to 1, will only echo commands (dry run)
# \env VERBOSE when set to 1 more verbose message
#
#############################################################################

if [ $# -ne 0 ]; then
	CONFIG_FILE=$1
else
	CONFIG_FILE="backup.cfg"
fi

if [ ! -f "$CONFIG_FILE" ]; then
	echo "configuration file $CONFIG_FILE not found"
	echo
	echo "usage: $0 [config_file] (or backup.cfg)"
	exit 1
fi

SOURCE_DIRS=()
SOURCE_DIRS_REMOTE=()
EXCLUDE_SOURCE_DIRS=()
DESTINATION_PARTITION=""
DESTINATION_DIR=""
RSYNC_SSH_OPTIONS=""

source $CONFIG_FILE

if [ ${#SOURCE_DIRS[@]} -eq 0 ] && [ ${#SOURCE_DIRS_REMOTE[@]} -eq 0 ]; then
	echo "SOURCE_DIRS and SOURCE_DIRS_REMOTE are both empty, nothing to do"
	exit 0
fi

#############################################################################

#############################################################################
# SIM -> Do something before the real command
# example : SIM="echo" will only show the commands, with no execution
#SIM="echo"
#############################################################################

#############################################################################
# RSYNC_FLAGS -> Flags used by rsync for xfer
#
RSYNC_FLAGS=()

# Make sure rsync don't cross file system boundaries
RSYNC_FLAGS+=("--one-file-system")

# Recursive, permission, links, ... MUST be managed
RSYNC_FLAGS+=("--archive")

# The files that need to be deleted should be deletet before xfer
# (useful when the destination is tight in space)
RSYNC_FLAGS+=("--delete-before")

# Copy hard links as hard links (Don't fill the destination disk with copies
# of files).
RSYNC_FLAGS+=("--hard-links")

# Manage sparse files
RSYNC_FLAGS+=("--sparse")

# Exclude dirs from config file

# Now ignore those path..
RSYNC_FLAGS+=("--exclude=/tmp")
RSYNC_FLAGS+=("--exclude=/var/lib/nagios3/spool/checkresults")

for EXCL in "${EXCLUDE_SOURCE_DIRS[@]}"
do
	RSYNC_FLAGS+=("--exclude=$EXCL")
done

# According to the FHS, those could be safely deleted
RSYNC_FLAGS+=("--exclude=/var/lock")
RSYNC_FLAGS+=("--exclude=/var/run")

#RSYNC_FLAGS+=("--compress")

#############################################################################
# Now do the copy
#

# Set IO priority to idle
ionice -c3 -p $$

# Set process priority to idle
renice 19 -p $$

SIM=${SIM:-"0"}

if [ "$SIM" != "0" ]; then
	SIM="echo"
else
	SIM=""
fi

VERBOSE=${VERBOSE:-"0"}

if [ "$VERBOSE" != "0" ]; then
	RSYNC_FLAGS+=("--verbose")
fi

$SIM echo "Backup start : $(date '+%F %T') DESTINATION_DIR:$DESTINATION_DIR"

if [ "$DESTINATION_PARTITION" != "" ]; then
	echo mounting $DESTINATION_PARTITION

	$SIM mount -o noatime $DESTINATION_PARTITION $DESTINATION_DIR
	if [ $? -ne 0 ]; then
		echo mounting failed, exiting
		exit -1
	fi
fi

for SRC in "${SOURCE_DIRS[@]}"
do
	echo backup "$SRC" into "$DESTINATION_DIR/$SRC"
	$SIM rsync "${RSYNC_FLAGS[@]}" "$SRC" "$DESTINATION_DIR/$SRC"
done

RSYNC_SSH_OPTIONS=${RSYNC_SSH_OPTIONS:-"ssh -T"}
RSYNC_FLAGS+=("-e" "$RSYNC_SSH_OPTIONS")
for SRC in "${SOURCE_DIRS_REMOTE[@]}"
do
	DST_DIR=${SRC//\//-}
	echo backup "$SRC" into "$DESTINATION_DIR/$DST_DIR"
	$SIM rsync "${RSYNC_FLAGS[@]}" "$SRC" "$DESTINATION_DIR/$DST_DIR"
done

$SIM df -h $DESTINATION_DIR

if [ "$DESTINATION_PARTITION" != "" ]; then
	echo unmounting $DESTINATION_PARTITION
	$SIM umount $DESTINATION_PARTITION
fi

$SIM echo "Backup end : $(date '+%F %T')"
