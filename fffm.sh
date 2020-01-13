#!/bin/sh

LOG_FILE='fffm.log'
CONF_FILE='fffm.conf'
METADATA_FILE='/tmp/fffm.metadata'

set -e

# Config
config() {
	#FFmpeg installation dir
	DIR_FFMPEG=$(find $( echo $PATH | tr -s ":" '\n' ) -name ffmpeg | rev | cut -d/ -f2- | rev )"/"

	if [[ "$DIR_FFMPEG" == "/" ]]; then
		echo "FFmpeg is not in your PATH"
		YN=n
		while [[ "$YN" == "n" ]]; do    
		echo "Where is it?"
		read -e DIR_FFMPEG
		if [[ "$DIR_FFMPEG" == "yolo" ]]; then #My ffmpeg folder is different, and I don't want to re-type everytime the folderm while debugging
			DIR_FFMPEG="$HOME""/Programmi/Compilati/ffmpeg/bin"
		fi
			echo "You chose the folder: $DIR_FFMPEG"
		ls "$DIR_FFMPEG"
		echo "Is it ok? (* = si, n = no)"
		read YN
		done
		DIR_FFMPEG="$DIR_FFMPEG"/
	   else
		echo "FFmpeg found in ""$DIR_FFMPEG"
	fi
	DIR_OUTPUT=""$HOME"/Musica"
	echo "Standard music directory is ~/Musica"
	echo "Modify it? (y = si, * = no)"
	read YN

	if [[ "$YN" == "y" ]]; then
		YN='';
		while [[ "$YN" != "y" ]]; do
			echo "Insert chosen directory"
			read -e DIR_OUTPUT
		if [[ "$DIR_OUTPUT" == "yolo" ]]; then #Same as ffmpeg
			DIR_OUTPUT="/media/nas/Musica"
		fi
			echo "You choose the directory: $DIR_OUTPUT"
		ls "$DIR_OUTPUT"
		echo "Is it ok? (y = si, * = no)"
			read YN
		done
		echo "DIR_OUTPUT" $DIR_OUTPUT >> log.txt
	fi

	echo "Select encoder and destination format"
	echo
	echo "	(a) libopus	(e) libmp3lame	(i) vorbis	" #Tab for showing what encoder are possible
	echo "	(b) libvorbis	(f) libfaac	(l) mp2		"
	echo "	(c) libfdk_aac	(g) eac3/ac3	(m) wmav2/wmav1	"
	echo "	(d) aac		(h) libtwolame			"
	echo
	PROFILE=''
	read ENCODER
	case "$ENCODER" in #Just reciclyng a variable
		a) 	ENCODER='libopus';
			EXTENSION='opus';;
		b) 	ENCODER='libvorbis';
			EXTENSION='ogg';;
		c) 	ENCODER='libfdk_aac'; #Damn you, fdk_aac
			echo "What profile do you want to use?"
			echo
			echo "	(*) Standard	(1) aac_he	(2) aac_he_v2	"
			read PROFILE
			case $PROFILE in
				1) PROFILE="-profile:a aac_he";;
				2) PROFILE="-profile:a aac_he_v2";;
				*) PROFILE="";;
			esac;
			EXTENSION='m4a';;
		d) 	ENCODER='aac';
			EXTENSION='m4a';;
		e) 	ENCODER='libmp3lame';
			EXTENSION='mp3';;
		f) 	ENCODER='libfaac';
			EXTENSION='m4a';;
		g) 	ENCODER='eac3/ac3';
			EXTENSION='ac3';;
		h) 	ENCODER='libtwolame';
			EXTENSION='mp2';;
		i)	ENCODER='vorbis';
			EXTENSION='ogg';;
		l) 	ENCODER='mp2';
			EXTENSION='mp2';;
		m) 	ENCODER='wmav2/wmav1';
			EXTENSION='wmv';;
	esac
	echo
	echo
	echo "Select bitrate (Write only the number)"
	echo
	echo "	16Kb/s	64Kb/s	160Kb/s	" #You can write every number, but those tabs are cool
	echo "	32Kb/s	96Kb/s	192Kb/s	"
	echo " 	48Kb/s	128Kb/s	320Kb/s	"
	echo
	read BITRATE

	DIR_FFPROBE=$(find $( echo $PATH | tr -s ":" '\n' ) -name ffprobe | rev | cut -d/ -f2- | rev )"/"


	if [[ $DIR_FFPROBE == "/" ]]; then
		echo "You ffprobe to use metadata fetching"
	fi

	TMP=$(find $( echo $PATH | tr -s ":" '\n' ) -name shnsplit)
	if [[ $TMP == "" ]]; then
		echo "Install shnsplit, if you want to use the splitter_cue.sh script"
	fi
	TMP=$(find $( echo $PATH | tr -s ":" '\n' ) -name cuetag.sh)
	if [[ $TMP == "" ]]; then
		echo "Install cuetools, if you want to use the splitter_cue.sh script"
	fi

	rm -f $CONF_FILE

	echo '#File di configurazione per lo script, modificare i valori o eseguire lo script config.sh' >> $CONF_FILE
	echo DIR_FFMPEG=$DIR_FFMPEG >> $CONF_FILE
	echo DIR_FFPROBE=$DIR_FFPROBE >> $CONF_FILE
	echo DIR_OUTPUT=$DIR_OUTPUT >> $CONF_FILE
	echo ENCODER=$ENCODER >> $CONF_FILE
	echo EXTENSION=$EXTENSION >> $CONF_FILE
	echo PROFILE=$PROFILE >> $CONF_FILE
	echo BITRATE=$BITRATE >> $CONF_FILE
}

# Splitter
splitter_cue ()
{
	echo "Thanks to sen for making this script"
	echo "https://bbs.archlinux.org/viewtopic.php?id=75774"
	sleep 1s #He deserves it
	SDIR=`pwd`

	if [ "$1" = "" ]
	  then
	    DIR=$SDIR
	else
	    case $1 in
	        -h | --help )
	            echo "Usage: cuesplit [Path]"
	            echo "       The default path is the current directory."
	            exit
	            ;;
	        * )
	        DIR=$1
	    esac
	fi
	
	echo -e "\
	
	Directory: $DIR
	________________________________________
	"
	cd "$DIR"
	TYPE=`ls -t1`

	case $TYPE in
	    *.ape*)
	        mkdir split
	        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.ape -t "%n - %t"
	        rm -f split/00*pregap*
	        cuetag.sh *.cue split/*.flac
	        exit
	        ;;
	
	    *.flac*)
	        mkdir split
	        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.flac -t "%n - %t"
	        rm -f split/00*pregap*
	        cuetag.sh *.cue split/*.flac
	        exit
	        ;;
	
	    *.mp3*)
	        mp3splt -no "@n @p - @t (split)" -c *.cue *.mp3
	        cuetag.sh *.cue *split\).mp3
	        exit
	        ;;
	
	    *.ogg*)
	        mp3splt -no "@n @p - @t (split)" -c *.cue *.ogg
    	    cuetag.sh *.cue *split\).ogg
        	exit
        	;;

	    *.tta*)
	        mkdir split
	        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.tta -t "%n - %t"
	        rm -f split/00*pregap*
	        cuetag.sh *.cue split/*.flac
	        exit
	        ;;
	
	    *.wv*)
	        mkdir split
	        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.wv -t "%n - %t"
	        rm -f split/00*pregap*
	        cuetag.sh *.cue split/*.flac
	        exit
	        ;;
	
	    *.wav*)
	        mkdir split
	        shnsplit -d split -f *.cue -o "flac flac -V --best -o %f -" *.wav -t "%n - %t"
	        rm -f split/00*pregap*
	        cuetag.sh *.cue split/*.flac
	        exit
	        ;;
	
	    * )
	    echo "Error: Found no files to split!"
	    echo "       --> APE, FLAC, MP3, OGG, TTA, WV, WAV"
	esac
}
	
printf "Script for organizing Music Files \nNOW WITH NEW FOLDER MANAGEMENT \n\n"

#Check dir input
if test "$1" = '--config' -o "$1" = '-c'; then
	config
fi
if test ! -d "$1"; then
    >&2 printf "Usage: %s [FLAC DIRECTORY]\n" $0
    exit
else
    DIR_INPUT="$1/"
fi

if [[ -r $CONF_FILE ]]; then
	source ./$CONF_FILE
else
	printf 'Necessario file di config, esegui %s --config\n' $0
	exit
fi

printf "Current configuration file:\n%s \nModify it? (y=yes, *=no)" "$(sed 1d < $CONF_FILE)" #The config should remain the same every time
read YN
if [ "$YN" = "y" ]; then
    YN=''
    config
fi

#Load config file
#CONFIG_FILE=$(tr -d [:blank:] < config.txt)
#DIR_FFMPEG=$(printf "%s" "$CONFIG_FILE"| grep FFMPEG | cut -d= -f2-)
#DIR_FFPROBE=$(printf "%s" "$CONFIG_FILE"| grep FFPROBE | cut -d= -f2-)
#DIR_OUTPUT=$(printf "%s" "$CONFIG_FILE"| grep OUTPUT | cut -d= -f2-)
#ENCODER=$(printf "%s" "$CONFIG_FILE"| grep ENCODER | cut -d= -f2-)
#EXTENSION=$(printf "%s" "$CONFIG_FILE"| grep EXTENSION | cut -d= -f2-)
#BITRATE=$(printf "%s" "$CONFIG_FILE"| grep BITRATE | cut -d= -f2-)

#Splitting CUE
CUE=0 #See later
if find "$DIR_INPUT"*.cue 1>/dev/null; then
    printf "There is a .cue file \nDo you need to split the .flac? (y=yes, *=no)"
    read YN
    if [ "$YN" = "y" ]; then
	YN=''
       	splitter_cue "$DIR_INPUT"
	CUE=1 #Needed a condition variable
	DIR_INPUT_ORIGINAL="$DIR_INPUT"  #Needed for copying the flac/cue version of the file
	DIR_INPUT="$DIR_INPUT"/split/ #New folder with the splitted flac files
    fi
fi

#Load Metadata
rm -f "$METADATA_FILE"

FIRST_FILE="$(find "$DIR_INPUT" -type f -name '*.flac' | head -1)"
"$DIR_FFPROBE"ffprobe "$FIRST_FILE" 2>> "$METADATA_FILE"
ARTISTA=$(grep -m 1 ARTIST "$METADATA_FILE" | cut -d: -f 2 | cut -c 2-)
ALBUM=$(grep -m 1 ALBUM "$METADATA_FILE" | cut -d: -f 2 | cut -c 2-)
ANNO=$(grep -m 1 DATE "$METADATA_FILE" | cut -d: -f 2 | cut -c 2-)


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
printf "DIR_OUTPUT %s\n" "$DIR_OUTPUT" >> $LOG_FILE #Logs are always useful


#Cover copier

cover(){
	printf "%s could this be the cover? (s: show, y: yes)\n" "$1"
	read YN
	if [ "$YN" = "s" ]; then
		img2txt --width=$(tput cols) "$1"
		printf "so?\n"
		read YN
	fi
	if [ "$YN" = "y" ]; then
		FILE=$(basename "$1")
		cp "$1" "$DIR_OUTPUT"/cover.$(printf "%s" "$FILE" | cut -d. -f2-)
		cp "$1" "$DIR_OUTPUT_FLAC"/cover.$(printf "%s" "$FILE" | cut -d. -f2-)
	fi
}

for j in {jpg,jpeg,png}; do 
	find "$DIR_INPUT" -type f -name '*'."$j" | while read i; do
		cover "$i" < /dev/tty
	done
done


#Converter
printf "Thanks to rubylaser for making the scheletron of this \nhttp://ubuntuforums.org/showthread.php?t=1705974\n"

LSSLESS_IN=$(find "$DIR_INPUT" -name "*.flac" -or -name "*.m4a" -or -name "*.caf" | head -n1 | rev | cut -d'.' -f1 | rev)

LSSLESS_IN="flac"

for i in "$DIR_INPUT"*."$LSSLESS_IN"; do
    if [ -e "$i" ]; then 
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
