#!/bin/bash
#############################################################################
#
# \brief Parallel convert a flac directory to a mp3 directory using mtime
#
# \warning does not re-create file when only this file changes
# \warning does not remove files from target directory
# \warning untested on directories not being subdirectories
#
# \url https://github.com/RandomReaper/scripts
#
# Copyright (c) 2017 Marc Pignat
# SPDX-License-Identifier: 	Apache-2.0
# License-Filename: LICENSE
#
#
#############################################################################

#############################################################################
# Configuration
#############################################################################

# Relative source sub directory
SOURCE_DIR="flac"

# Relative output sub directory
DEST_DIR="mp3-from-flac"

# Encoding options (see lave -v)
# For VBR
#LAME_QUALITY_P1="-q:a"
#LAME_QUALITY_P2="0"
# For CBR
LAME_QUALITY_P1="-ab"
LAME_QUALITY_P2="192k"

#############################################################################
# Check required tools
#############################################################################
# avconv and parallel >= 20160422 are required

command -v parallel >/dev/null 2>&1 || { echo >&2 "GNU parallel not found.  Aborting."; exit 1; }
parallel --no-notice --link echo ::: A B C ::: D E F >/dev/null 2>&1 || { echo >&2 "GNU parallel found, but verion < 20160422.  Aborting."; exit 1; }
command -v avconv  >/dev/null 2>&1 || { echo >&2 "avconv not found.  Aborting."; exit 1; }

#############################################################################
# Find FLAC files (by extension)
#############################################################################
flacs=()
while IFS=  read -r -d $'\0'; do
    flacs+=("$REPLY")
done < <(find "$SOURCE_DIR" -iname "*.flac" -print0 | sort -zn)


#############################################################################
# Generate destination file list
#############################################################################

# replace .flac by .mp3
mp3s=( "${flacs[@]/\.[fF][lL][aA][cC]/\.mp3}" )

# replace SOURCE_DIR by DEST_DIR
mp3s=( "${mp3s[@]/$SOURCE_DIR/$DEST_DIR}" )

#############################################################################
# Keep only files if flac have newer date than mp3, or mp3 does not exist
#############################################################################
echo ${#flacs[@]} flac files found 

src=()
dst=()
for i in "${!mp3s[@]}"
do
    if [[ "${flacs[$i]}" -nt "${mp3s[$i]}" ]]; then
    	src+=("${flacs[$i]}")
    	dst+=("${mp3s[$i]}")
	fi
done
flacs=("${src[@]}")
mp3s=("${dst[@]}")

echo ${#mp3s[@]} files to convert

#############################################################################
# Create directories for the missing destination files
# TODO: could be optimized (mkdir -p and called multiple times)
#############################################################################
for i in "${!mp3s[@]}"
do
	mkdir -p "$(dirname "${mp3s[$i]}")"
done

#############################################################################
# Now convert the files
#############################################################################

if [ ${#mp3s[@]} -eq 0 ]; then
    exit 0
fi

parallel --no-notice -k --link -q --progress \
	::: avconv ::: -y ::: -v ::: error ::: -i ::: "${flacs[@]}" ::: -codec:a ::: libmp3lame :::\
	"${LAME_QUALITY_P1}" ::: "${LAME_QUALITY_P2}" ::: "${mp3s[@]}"

