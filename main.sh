#!/bin/sh

printf "Script for organizing Music Files \nNOW WITH NEW FOLDER MANAGEMENT \n\n"

#Check dir input
if [ ! -d "$1" ]; then
    >&2 printf "Usage: ./main.sh [FLAC DIRECTORY]\n"
    return 1
else
    DIR_INPUT="$1/"
fi
printf "Current configuration file:\n%s \nModify it? (y=yes, *=no)" "$(sed 1d < config.txt)" #The config should remain the same every time
read YN
if [ "$YN" = "y" ]; then
    YN=''
    ./config.sh
fi

#Load config file
CONFIG_FILE=$(tr -d [:blank:] < config.txt)
DIR_FFMPEG=$(printf "%s" "$CONFIG_FILE"| grep FFMPEG | cut -d= -f2-)
DIR_FFPROBE=$(printf "%s" "$CONFIG_FILE"| grep FFPROBE | cut -d= -f2-)
DIR_EXIFTOOL=$(printf "%s" "$CONFIG_FILE"| grep EXIFTOOL | cut -d= -f2- | sed s/"(".*.")"// )
EXIFTOOL=$(printf "%s" "$CONFIG_FILE"| grep EXIFTOOL | cut -d"(" -f2- | sed 's/.$//' )
DIR_OUTPUT=$(printf "%s" "$CONFIG_FILE"| grep OUTPUT | cut -d= -f2-)
ENCODER=$(printf "%s" "$CONFIG_FILE"| grep ENCODER | cut -d= -f2-)
EXTENSION=$(printf "%s" "$CONFIG_FILE"| grep EXTENSION | cut -d= -f2-)
BITRATE=$(printf "%s" "$CONFIG_FILE"| grep BITRATE | cut -d= -f2-)

#Input files
#YN="n" #Maybe a do-while would be better
#while [ "$YN" = "n" ]; do
#    printf "Where are the music files to be organized?"
#    bash read -e DIR_INPUT
#    printf "You choose the folder: %s""$DIR_INPUT" #Check
#    ls "$DIR_INPUT" #Double check
#    DIR_INPUT="$DIR_INPUT""/" 
#    printf "Is it ok? (* = yes, y = no)"
#    read YN
#done


#Splitting CUE
CUE=0 #See later
if find "$DIR_INPUT"*.cue 1>/dev/null; then
    printf "There is a .cue file \nDo you need to split the .flac? (y=yes, *=no)"
    read YN
    if [ "$YN" = "y" ]; then
	YN=''
       	./splitter_cue.sh "$DIR_INPUT"
	CUE=1 #Needed a condition variable
	DIR_INPUT_ORIGINAL="$DIR_INPUT"  #Needed for copying the flac/cue version of the file
	DIR_INPUT="$DIR_INPUT"/split/ #New folder with the splitted flac files
    fi
fi

#Load Metadata
rm metadata.txt

if [ "$EXIFTOOL" = "y" ]; then
    "$DIR_EXIFTOOL"exiftool "$DIR_INPUT"*.flac | \
	grep -v Directory | grep -v "File Name" | grep -v "======="  | grep -v "Date/Time" >> metadata.txt
    ARTISTA=$(grep -m 1 Artist metadata.txt | cut -d: -f 2 | cut -c 2-)
    ALBUM=$(grep -m 1 Album metadata.txt | cut -d: -f 2 | cut -c 2-)
    ANNO=$(grep -m 1 Date metadata.txt | cut -d: -f 2 | cut -c 2-)
else
    FIRST_FILE="$DIR_INPUT"$(ls "$DIR_INPUT" | head -1)
    "$DIR_FFPROBE"ffprobe "$FIRST_FILE" 2>> metadata.txt
    ARTISTA=$(grep -m 4 ARTIST metadata.txt | cut -d: -f 2 | cut -c 2-)
    ALBUM=$(grep -m 1 ALBUM metadata.txt | cut -d: -f 2 | cut -c 2-)
    ANNO=$(grep -m 1 DATE metadata.txt | cut -d: -f 2 | cut -c 2-)
fi
printf "The Artist is: %s \nThe Album is: %s \nThe Year is: %s \nCorrect? (* = yes, n = no)\n" "$ARTISTA" "$ALBUM" "$ANNO" #Error checking
read YN
if [ "$YN" = "n" ]; then #There Might be Errors
    printf "What is the Artist?\t"
    read ARTISTA
    printf "What is the Album?\t"
    read ALBUM
    printf "What is the Year?\t"
    read ANNO
fi

#Folder Creation
DIR_OUTPUT_FLAC="$DIR_OUTPUT"/FLAC/"$ARTISTA"/"$ANNO - $ALBUM"
DIR_OUTPUT_FLAC_CUE="$DIR_OUTPUT"/"FLAC - CUE"/"$ARTISTA"/"$ANNO - $ALBUM"
DIR_OUTPUT="$DIR_OUTPUT"/$(printf "$EXTENSION" | tr [:lower:] [:upper:])" - ""$BITRATE"" KBs"/"$ARTISTA"/"$ANNO - $ALBUM"

if [ $CUE -eq 1 ]; then
    mkdir -p "$DIR_OUTPUT_FLAC_CUE"
    cp "$DIR_INPUT_ORIGINAL"/*.flac "$DIR_OUTPUT_FLAC_CUE"
    cp "$DIR_INPUT_ORIGINAL"/*.cue "$DIR_OUTPUT_FLAC_CUE"
fi

printf "%s\n" "$DIR_OUTPUT" #Debug


#ACTUAL Folder Creation
mkdir -p "$DIR_OUTPUT"/
mkdir -p "$DIR_OUTPUT_FLAC"
printf "DIR_OUTPUT %s\n" "$DIR_OUTPUT" >> log.txt #Logs are always useful


#Cover copier
#find "$DIR_INPUT" -name "*.png" -or -name "*.jpg" | while read i; do
#	img2txt --width=$(tput cols) "$i"
#	printf "could this be the cover?"
#	read YN
#	if [ "$YN" = "y" ]; then
#		FILE=$(basename "$i")
#		cp "$i" "$DIR_OUTPUT"/"cover".$(printf "%s" "$FILE" | cut -d. -f2-)
#		cp "$i" "$DIR_OUTPUT_FLAC"/"cover".$(printf "%s" "$FILE" | cut -d. -f2-)
#	fi
#done


#Converter
printf "Thanks to rubylaser for making the scheletron of this \nhttp://ubuntuforums.org/showthread.php?t=1705974"

LSSLESS_IN=$(find "$DIR_INPUT" -name "*.flac" -or -name "*.m4a" -or -name "*.caf" | head -n1 | rev | cut -d'.' -f1 | rev)

echo "$LSSLESS_IN"

for i in "$DIR_INPUT"*."$LSSLESS_IN"; do
    if [ -e "$i" ]; then #Dont know why I put this here, but too afraid to remove it
		TRACK=$(( $TRACK + 1 ))
		file=$(basename -s ."$LSSLESS_IN" "$i") #.flac.opus isn't cool
		"$DIR_FFMPEG"ffmpeg -i  "$i" \
			     -c:a "$ENCODER" -b:a "$BITRATE"k  \
			     -metadata author="$ARTISTA" -metadata album="$ALBUM" -metadata year="$ANNO" -metadata track="$TRACK" \
			     "$DIR_OUTPUT"/"$file"."$EXTENSION"
		if [ "$LSSLESS_IN" == "flac" ]; then
			cp "$i" "$DIR_OUTPUT_FLAC" #Don't fotget the actual flac file
		else
			"$DIR_FFMPEG"ffmpeg -i "$i" "$DIR_OUTPUT_FLAC"/"$file".flac
		fi
	fi
done
