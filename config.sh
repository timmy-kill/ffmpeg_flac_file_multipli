#!/bin/bash

#Script made for storing the users preference

CONF_FILE='fffm.conf'

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
echo FFMPEG=$DIR_FFMPEG >> $CONF_FILE
echo FFPROBE=$DIR_FFPROBE >> $CONF_FILE
echo DIR_OUTPUT=$DIR_OUTPUT >> $CONF_FILE
echo ENCODER=$ENCODER >> $CONF_FILE
echo EXTENSION=$EXTENSION >> $CONF_FILE
echo PROFILE=$PROFILE >> $CONF_FILE
echo BITRATE=$BITRATE >> $CONF_FILE
