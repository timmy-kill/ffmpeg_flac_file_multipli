#!/bin/bash

clear
echo "Script per l'organizzazzione dei file musicali"
echo
while [ "$yn" != "y" ]; do
        echo "Inserire la directory in cui sono locati i file musicali"
        read -e DIR_INPUT
        echo "Hai scelto la cartella: $DIR_INPUT"
        ls "$DIR_INPUT"
        echo "Va bene? (y = si, * = no)"
        read yn
done

DIR_OUTPUT='/media/nas/Musica'
echo "La cartella standard per la musica e' $DIR_OUTPUT"
echo "Modificarla? (y = si, * = no)"
read yn

if [ "$yn" == "y" ]; then
       while [ "$yn" != "y" ]; do
                echo "Inserire la directory da utilizzare"
                read -e DIR_OUTPUT
                echo "Hai scelto la cartella: $DIR_OUTPUT"
                echo "Va bene? (y = si, * = no)"
                read yn
                done
        echo "DIR_OUTPUT" $DIR_OUTPUT >> /var/log/ffmpeg_multiple_audio_converter.log
fi



echo "Ora verra' creata la cartella che conterra' la musica"
echo
echo
exiftool "$DIR_INPUT"* > metadata.txt
cat metadata.txt
echo
echo
echo "Tutto ok?"
read yn
if [ "$yn" == "yes" ] || [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
artista=$(grep -m 1 Artist metadata.txt)
prefisso="Artist                          : "
artista=$(echo "$artista" | sed "s/^$prefisso//")
album=$(grep -m 1 Album metadata.txt)
prefisso="Album                           : "
album=$(echo "$album" | sed "s/^$prefisso//")
else
	echo "Qual'e' l'artista?"
	read artista
	echo "Qual'e' l'album?"
	read album
fi
DIR_OUTPUT=$(echo "$DIR_OUTPUT"/"$artista")
DIR_OUTPUT=$(echo "$DIR_OUTPUT"/"$album")
echo "$DIR_OUTPUT"



echo
echo
echo "Selezionare encoder e formato di destinazione"
echo
echo "	(a) libopus	(e) libmp3lame	(i) vorbis	" #fornisce una grigllia in output per la scelta del encoder
echo "	(b) libvorbis	(f) libfaac	(l) mp2		"
echo "	(c) libfdk_aac	(g) eac3/ac3	(m) wmav2/wmav1	"
echo "	(d) aac		(h) libtwolame			"
echo
read encoder
case $encoder in #la variabile encoder viene riutilizzata per contenere la stringa
	a) 	encoder='libopus';
		extension='opus';;
	b) 	encoder='libvorbis';
		extension='ogg';;
	c) 	encoder='libfdk_aac'; #libfdk contiene diversi profili
		echo "Che profilo utilizzare?"
		echo
		echo "	(*) Standard	(1) aac_he	(2) aac_he_v2	"
		read profilo
		case $profilo in
			1) profilo="-profile:a aac_he";;
			2) profilo="-profile:a aac_he_v2";;
			*) profilo="";;
		esac;
		extension='m4a';;
	d) 	encoder='aac';
		extension='m4a';;
	e) 	encoder='libmp3lame';
		extension='mp3';;
	f) 	encoder='libfaac';
		extension='m4a';;
	g) 	encoder='eac3/ac3';
		extension='ac3';;
	h) 	encoder='libtwolame';
		extension='mp2';;
	i)	encoder='vorbis';
		extension='ogg';;
	l) 	encoder='mp2';
		extension='mp2';;
	m) 	encoder='wmav2/wmav1';
		extension='wmv';;
esac
echo
echo
echo "Selezionare Bitrate (scrivere solo il numero)"
echo
echo "	16Kb/s	64Kb/s	160Kb/s	" #questo serve solo come guida, quasiasi valore verra' accettato
echo "	32Kb/s	96Kb/s	192Kb/s	"
echo " 	48Kb/s	128Kb/s	320Kb/s	"
echo
read bitrate


mkdir -p "$DIR_OUTPUT"/ #crea, nel caso la cartella non sia gia' esistente, la directory di destinazione
echo "DIR_OUTPUT" $DIR_OUTPUT >> log_ffpmeg-script.txt #crea un log della cartella appena creata, in caso ci si$


for i in "$DIR_INPUT"*.flac; do
	if [ -e "$i" ]; then
   		file=`basename "$i" .flac`
  		ffmpeg -i  "$i" -c:a "$encoder" -b:a "$bitrate"k  "$DIR_OUTPUT"/"$file"."$extension"
	fi
done
