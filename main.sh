#!/bin/bash

echo "Script per l'organizzazzione di file flac"
echo
echo "La configurazione attuale è la seguente"
cat config.txt
echo
echo
echo "Modificarla?"
read yn
if [ "$yn" == "y" ]; then
    yn=''
    ./config.sh
fi

#Load config file
FFMPEG=$(cat config.txt| grep FFMPEG | sed "s/FFMPEG = //")
OUTPUT=$(cat config.txt| grep OUTPUT | sed "s/OUTPUT = //")
ENCODER=$(cat config.txt| grep ENCODER | sed "s/ENCODER = //")
EXTENSION=$(cat config.txt| grep EXTENSION | sed "s/EXTENSION = //")
BITRATE=$(cat config.txt| grep BITRATE | sed "s/BITRATE = //")

#Input files
while [ "$yn" != "y" ]; do
        echo "Inserire la directory in cui sono locati i file musicali"
        read -e DIR_INPUT
        echo "Hai scelto la cartella: $DIR_INPUT"
        ls "$DIR_INPUT"
        echo "Va bene? (y = si, * = no)"
        read yn
done
