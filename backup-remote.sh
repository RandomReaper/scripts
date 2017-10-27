#!/bin/bash
#############################################################################
#
# \brief Backup script from a mounted system to a directory
# \author Author : Marc pignat (email : <firt name>@<last name>.org
#
# \warning Don't change the RSYNC_FLAGS unless you know what you're doing ;)
#
#############################################################################

#
# DESTINATION_DIR
#
DESTINATION_DIR="/backup"

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
# Make sure rsync don't cross file system boundaries
#
RSYNC_FLAGS=()
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

RSYNC_FLAGS+=("--compress")

# RSYNC_FLAGS+=("--verbose" # for a more verbose script
RSYNC_FLAGS+=("--verbose")


#############################################################################

$SIM echo "Backup start : $(date '+%F %T')"
DESTINATION_DIR=$DESTINATION_DIR

for SRC in ${SOURCE_DIRS[@]}
do
	$SIM echo backup $SRC
	$SIM rsync "${RSYNC_FLAGS[@]}" "$SRC" "$DESTINATION_DIR"
done
$SIM echo "Backup end : $(date '+%F %T')"


