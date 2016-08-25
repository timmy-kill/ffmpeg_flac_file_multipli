#!/bin/bash

echo "Script for organizing Music Files"
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
FFMPEG=$(echo "$CONFIG_FILE"| grep FFMPEG | sed "s/FFMPEG=//")
DIR_OUTPUT=$(echo "$CONFIG_FILE"| grep OUTPUT | sed "s/OUTPUT=//")
ENCODER=$(echo "$CONFIG_FILE"| grep ENCODER | sed "s/ENCODER=//")
EXTENSION=$(echo "$CONFIG_FILE"| grep EXTENSION | sed "s/EXTENSION=//")
BITRATE=$(echo "$CONFIG_FILE"| grep BITRATE | sed "s/BITRATE=//")

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
exiftool "$DIR_INPUT"*.flac >> metadata.txt
ARTISTA=$(grep -m 1 Artist metadata.txt)
PREFISSO="Artist                          : " #This variable make the whole thing cleaner, I guess
ARTISTA=$(echo "$ARTISTA" | sed "s/^$PREFISSO//")
ALBUM=$(grep -m 1 Album metadata.txt)
PREFISSO="Album                           : " #Same
ALBUM=$(echo "$ALBUM" | sed "s/^$PREFISSO//")
ANNO=$(grep -m 1 "Date                            : " metadata.txt)
PREFISSO="Date                            : "
ANNO=$(echo "$ANNO" | sed "s/^$PREFISSO//")
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

#Kind of useless stuff
# id3 -a "$ARTISTA" -l "$ALBUM" "$DIR_INPUT"*.flac #Id3 Tagging
# id3 -2 -a "$ARTISTA" -l "$ALBUM" "$DIR_INPUT"*.flac #Id3v2 Tagging

#Folder Creation
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/""$ARTISTA""/""$ANNO - $ALBUM")
if [ $CUE == 1 ]; then  #That condition... wait, I can do it in another way
    mkdir -p "$DIR_OUTPUT"/FLAC\ -\ CUE #This should be on the next part
    cp "$DIR_INPUT_ORIGINAL"/*.flac "$DIR_OUTPUT"/FLAC\ -\ CUE
    cp "$DIR_INPUT_ORIGINAL"/*.cue "$DIR_OUTPUT"/FLAC\ -\ CUE
fi
DIR_OUTPUT_FLAC=$(echo "$DIR_OUTPUT"/FLAC) #I really Hate This Variable
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/"$(echo "$EXTENSION" | tr [:lower:] [:upper:])" - ""$BITRATE"" KBs") # I need the extension to be uppercase, or I'll freak out
echo "$DIR_OUTPUT" #Debug

#ACTUAL Folder Creation
mkdir -p "$DIR_OUTPUT"/
mkdir -p "$DIR_OUTPUT_FLAC"
echo "DIR_OUTPUT" $DIR_OUTPUT >> log.txt #Logs are always useful

#Converter
echo "Thanks to rubylaser for making the scheletron of this"
echo "http://ubuntuforums.org/showthread.php?t=1705974"
for i in "$DIR_INPUT"*.flac; do
    if [ -e "$i" ]; then
	file=$(basename -s .flac "$i") #.flac.opus isn't cool
  	"$DIR_FFMPEG"ffmpeg -i  "$i" -c:a "$ENCODER" -b:a "$BITRATE"k  "$DIR_OUTPUT"/"$file"."$EXTENSION"
	cp "$i" "$DIR_OUTPUT_FLAC" #Don't fotget the actual flac file
    fi
done

#Cover Copier
#To be done
echo
echo
echo "You'll need to copy folder and .accurip files by your own"
echo "Sorry :D"
