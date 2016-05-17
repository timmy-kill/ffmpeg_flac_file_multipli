#!/bin/bash

#Questa parte di script serve a definire le impostazioni standard per l'utente

rm -f config.txt

echo "La directory standard di ffmpeg è ~/bin"
DIR_FFMPEG="~/bin"
echo "Cambiarla? (y = si, * = no)"
read yn
if [ "$yn" == "y" ]; then
    yn='reset';
    while [ "$yn" != "y" ]; do
	echo "Inserire la directory che si vuole utilizzare"
	read -e DIR_FFMPEG
	
	if [ "$DIR_FFMPEG" == "yolo" ]; then #la mia directory di installazione di ffmpeg è diversa, e per moltivi legati al debug voglio semplificare la configurazione della stessa  
	    DIR_FFMPEG="$HOME""/Programmi/Compilati/ffmpeg/bin"
	fi

	echo "Hai scelto la cartella: $DIR_FFMPEG"
	ls "$DIR_FFMPEG"
	echo "Va bene? (y = si, * = no)"
	read yn
    done
fi


DIR_OUTPUT='~/Musica'
echo "La cartella standard per la musica e' $DIR_OUTPUT"
echo "Modificarla? (y = si, * = no)"
read yn

if [ "$yn" == "y" ]; then
    yn='reset';
    while [ "$yn" != "y" ]; do
        echo "Inserire la directory da utilizzare"
        read -e DIR_OUTPUT
	if [ "$DIR_OUTPUT" == "yolo" ]; then
	    DIR_OUTPUT="/media/nas"
	fi
        echo "Hai scelto la cartella: $DIR_OUTPUT"
	ls "$DIR_OUTPUT"
	echo "Va bene? (y = si, * = no)"
        read yn
    done
    echo "DIR_OUTPUT" $DIR_OUTPUT >> log.txt
fi

echo "Selezionare encoder e formato di destinazione"
echo
echo "	(a) libopus	(e) libmp3lame	(i) vorbis	" #fornisce una grigllia in output per la scelta del encoder
echo "	(b) libvorbis	(f) libfaac	(l) mp2		"
echo "	(c) libfdk_aac	(g) eac3/ac3	(m) wmav2/wmav1	"
echo "	(d) aac		(h) libtwolame			"
echo
read ENCODER
case $ENCODER in #la variabile encoder viene riutilizzata per contenere la stringa
	a) 	ENCODER='libopus';
		EXTENSION='opus';;
	b) 	ENCODER='libvorbis';
		EXTENSION='ogg';;
	c) 	ENCODER='libfdk_aac'; #libfdk contiene diversi profili
		echo "Che profilo utilizzare?"
		echo
		echo "	(*) Standard	(1) aac_he	(2) aac_he_v2	"
		read PROFILO
		case $PROFILO in
			1) PROFILO="-profile:a aac_he";;
			2) PROFILO="-profile:a aac_he_v2";;
			*) PROFILO="";;
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
echo "Selezionare Bitrate (scrivere solo il numero)"
echo
echo "	16Kb/s	64Kb/s	160Kb/s	" #questo serve solo come guida, quasiasi valore verra' accettato
echo "	32Kb/s	96Kb/s	192Kb/s	"
echo " 	48Kb/s	128Kb/s	320Kb/s	"
echo
read BITRATE


echo "File di configurazione per lo script, modificare i valori o eseguire lo script 'config.sh'" >> config.txt
echo "FFMPEG = " $DIR_FFMPEG >> config.txt
echo "OUTPUT = " $DIR_OUTPUT >> config.txt
echo "ENCODER = " $ENCODER >> config.txt
echo "EXTENSION = " $EXTENSION >> config.txt
echo "BITRATE = " $BITRATE >> config.txt
