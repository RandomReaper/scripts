#!/bin/bash
#############################################################################
#
# \brief Backup script over ssh+rsync system to a directory
#
# \warning Don't change the RSYNC_FLAGS unless you know what you're doing ;)
#
# \url https://github.com/RandomReaper/scripts
# 
# Copyright (c) 2017 Marc Pignat
# SPDX-License-Identifier: 	Apache-2.0
# License-Filename: LICENSE
#
# \env SIM
# \env VERBOSE
#
#############################################################################

#
# DESTINATION_DIR
#
DESTINATION_DIR="/backup"

#############################################################################
# Sources and destination
#
# SOURCE_DIRS -> List of source directories
# rsync will stay in one file system, so for a complete backup
# SOURCE_DIRS will be the list of the mount points
#
SOURCE_DIRS=()
SOURCE_DIRS+=("root@SERVER_IP:/etc")

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

# Remote
RSYNC_FLAGS+=("-e ssh -T")

# The files that need to be deleted should be deletet before xfer
# (useful when the destination is tight in space)
RSYNC_FLAGS+=("--delete-before")

# Copy hard links as hard links (Don't fill the destination disk with copies
# of files).
RSYNC_FLAGS+=("--hard-links")

# Manage sparse files
RSYNC_FLAGS+=("--sparse")

# Now ignore those path..
RSYNC_FLAGS+=("--exclude=/tmp")
RSYNC_FLAGS+=("--exclude=/var/lib/nagios3/spool/checkresults")

# According to the FHS, those could be safely deleted
RSYNC_FLAGS+=("--exclude=/var/lock")
RSYNC_FLAGS+=("--exclude=/var/run")

#RSYNC_FLAGS+=("--compress")

# RSYNC_FLAGS+=("--verbose" # for a more verbose script
RSYNC_FLAGS+=("--verbose")

#############################################################################
# Now do the copy
#

ionice -c3 -p $$
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

$SIM echo "Backup start : $(date '+%F %T')"

for SRC in ${SOURCE_DIRS[@]}
do
	$SIM echo backup $SRC
	$SIM rsync "${RSYNC_FLAGS[@]}" "$SRC" "$DESTINATION_DIR"
done
$SIM df -h $DESTINATION_DIR

$SIM echo "Backup end : $(date '+%F %T')"
