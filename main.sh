#!/bin/bash

echo "Script for organizing Music Files"
echo "NOW WITH NEW FOLDER MANAGEMENT"
echo
echo "Now the configuration file is this one" #The config should remain the same every time 
cat config.txt | sed 1d
echo
echo
echo "Modify it? (y=yes, *=no)"
read YN
if [ "$YN" == "y" ]; then
    YN=''
    ./config.sh
fi

#Load config file
CONFIG_FILE=$(cat config.txt | tr -d [:blank:])
DIR_FFMPEG=$(echo "$CONFIG_FILE"| grep FFMPEG | cut -d= -f2-)
DIR_FFPROBE=$(echo "$CONFIG_FILE"| grep FFPROBE | cut -d= -f2-)
DIR_EXIFTOOL=$(echo "$CONFIG_FILE"| grep EXIFTOOL | cut -d= -f2- | sed s/"(".*.")"// )
EXIFTOOL=$(echo "$CONFIG_FILE"| grep EXIFTOOL | cut -d"(" -f2- | sed 's/.$//' )
DIR_OUTPUT=$(echo "$CONFIG_FILE"| grep OUTPUT | cut -d= -f2-)
ENCODER=$(echo "$CONFIG_FILE"| grep ENCODER | cut -d= -f2-)
EXTENSION=$(echo "$CONFIG_FILE"| grep EXTENSION | cut -d= -f2-)
BITRATE=$(echo "$CONFIG_FILE"| grep BITRATE | cut -d= -f2-)

#Input files
YN="n" #Maybe a do-while would be better
while [ "$YN" == "n" ]; do
    echo "Where are the music files to be organized?"
    read -e DIR_INPUT
    echo "You choose the folder: ""$DIR_INPUT" #Check
    ls "$DIR_INPUT" #Double check
    DIR_INPUT="$DIR_INPUT""/" 
    echo "Is it ok? (* = yes, y = no)"
    read YN
done

#Splitting CUE
CUE=0 #See later
if [ -e "$DIR_INPUT"*.cue ]; then
    echo "There is a .cue file"
    echo "Do you need to split the .flac? (y=yes, *=no)"
    read YN
    if [ "$YN" == "y" ]; then
	YN=''
       	./splitter_cue.sh "$DIR_INPUT"
	CUE=1 #Needed a condition variable
	DIR_INPUT_ORIGINAL="$DIR_INPUT"  #Needed for copying the flac/cue version of the file
	DIR_INPUT="$DIR_INPUT"/split/ #New folder with the splitted flac files
    fi
fi

#Load Metadata
rm metadata.txt

if [[ $EXIFTOOL == "y" ]]; then
#if true; then
    "$DIR_EXIFTOOL"exiftool "$DIR_INPUT"*.flac | \
	grep -v Directory | grep -v "File Name" | grep -v "======="  | grep -v "Date/Time" >> metadata.txt
    ARTISTA=$(grep -m 1 Artist metadata.txt | cut -d: -f 2 | cut -c 2-)
    ALBUM=$(grep -m 1 Album metadata.txt | cut -d: -f 2 | cut -c 2-)
    ANNO=$(grep -m 1 Date metadata.txt | cut -d: -f 2 | cut -c 2-)
else
    FIRST_FILE=("$DIR_INPUT"*.flac)
    "$DIR_FFPROBE"ffprobe "$FIRST_FILE" 2>> metadata.txt
    ARTISTA=$(grep -m 1  ARTIST metadata.txt | cut -d: -f 2 | cut -c 2-)
    ALBUM=$(grep -m 1   ALBUM metadata.txt | cut -d: -f 2 | cut -c 2-)
    ANNO=$(grep -m 1  DATE metadata.txt | cut -d: -f 2 | cut -c 2-)
fi
echo "The Artist is" $ARTISTA #Check for errors
echo "The Album is" $ALBUM
echo "The Year is" $ANNO
echo "Correct? (* = yes, n = no)"
read YN
if [ $YN == "n" ]; then #There Might be Errors
    echo "What is the Artist?"
    read ARTISTA
    echo "What is the Album?"
    read ALBUM
    echo "What is the Year?"
    read ANNO
fi

#Folder Creation
DIR_OUTPUT_FLAC="$DIR_OUTPUT"/FLAC/"$ARTISTA"/"$ANNO - $ALBUM"
DIR_OUTPUT_FLAC_CUE="$DIR_OUTPUT"/"FLAC - CUE"/"$ARTISTA"/"$ANNO - $ALBUM"
DIR_OUTPUT="$DIR_OUTPUT"/$(echo "$EXTENSION" | tr [:lower:] [:upper:])" - ""$BITRATE"" KBs"/"$ARTISTA"/"$ANNO - $ALBUM"

if [ $CUE == 1 ]; then  #That condition... wait, I can do it in another way
    mkdir -p "$DIR_OUTPUT_FLAC_CUE" #This should be on the next part
    cp "$DIR_INPUT_ORIGINAL"/*.flac "$DIR_OUTPUT_FLAC_CUE"
    cp "$DIR_INPUT_ORIGINAL"/*.cue "$DIR_OUTPUT_FLAC_CUE"
fi

echo "$DIR_OUTPUT" #Debug


#ACTUAL Folder Creation
mkdir -p "$DIR_OUTPUT"/
mkdir -p "$DIR_OUTPUT_FLAC"
echo "DIR_OUTPUT" $DIR_OUTPUT >> log.txt #Logs are always useful


#Cover copier
for i in "$DIR_INPUT"*.png; do
	img2txt --width=$(tput cols) "$i"
	echo "could this be the cover?"
	read YN
	if [ "$YN" == "y" ]; then
		FILE=$(basename "$i")
		cp "$i" "$DIR_OUTPUT"/"cover".$(echo "$FILE" | cut -d. -f2-)
		cp "$i" "$DIR_OUTPUT_FLAC"/"cover".$(echo "$FILE" | cut -d. -f2-)
	fi
done


#Converter
echo "Thanks to rubylaser for making the scheletron of this"
echo "http://ubuntuforums.org/showthread.php?t=1705974"

for i in "$DIR_INPUT"*.flac; do
    if [ -e "$i" ]; then
	TRACK=$(( $TRACK + 1 ))
	file=$(basename -s .flac "$i") #.flac.opus isn't cool
   	"$DIR_FFMPEG"ffmpeg -i  "$i" \
		     -c:a "$ENCODER" -b:a "$BITRATE"k  \
		     -metadata author="$ARTISTA" -metadata album="$ALBUM" -metadata year="$ANNO" -metadata track="$TRACK" \
		     "$DIR_OUTPUT"/"$file"."$EXTENSION"
	
	cp "$i" "$DIR_OUTPUT_FLAC" #Don't fotget the actual flac file
    fi
done


#To be done
echo
echo
echo "You'll need to copy folder and .accurip files by your own"
echo "Sorry :D"
0
