#!/bin/bash
# Smiril
# 04.11.2018
# ReAddition zu Homee Script für den autostart Folder
# Smiril
# 03.11.2018
# Modifizierte version von proScanner.sh
# getestet auf "Debian" + "Raspberry pi 3 B+"
# Julian
# 24.07.2017
# Comment:
# Script läuft nach dem Start des RPI und Dauerschleife
# wenn beide G-tags 15 Schleifendurchläufe nicht erkannt werden
# wird auf Status Abwesend gesetzt
# -------------------------
# Einstellungen (edit here)
# -------------------------
away=4 	# nach wieviel checkback Durchläufen Status "abwesend"?
TAGS=("7A:55:6C:0B:A5:D0" "6C:B0:B1:B3:C0:0F") # G-tags mac Adresses
NAMES=("ONE" "TWO") #namen für devices
homeeip="192.168.178.5"
homeeport="7681"
webhooks_key="AAAAAAAAAAAAABBBBBBBBBBCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDEEEEEEEE"
# ----------------------
# do not edit below here 
# ----------------------
# Startverzögerung
echo "G-tag Scanner for X"
echo ""
i=5
while [[ $i -gt 0 ]]; do
	sleep 1
	echo "starts in "$i
	i=$[$i-1]
done
ncounter=1
daheim=0
# Whitelist clear
sudo hcitool lewlclr
# G-tags zur Whitelist
echo "Gültige G-tags"
for k in ${TAGS[*]}; do
	echo "$k"
	sudo hcitool lewladd "$k"
	if [ $? -eq 1 ]; then
		echo "Bluetooth error; not installed?"
		exit
	fi
done
echo ""
while true; do
    echo "Scanning ..."
    sudo hcitool lescan --whitelist | grep -v "LE Scan ..." > scan.txt & sleep 2 && sudo pkill --signal SIGINT hcito   
    for a in ${!TAGS[*]}; do
    NUMOFLINES=$(grep -f scan.txt -E "scan.txt")
    if [ "$NUMOFLINES" == ${TAGS[a]} ]; then
		# Anwesend
		if [ "$daheim" -eq 0 ]; then
			echo "Status: anwesend ${NAMES[a]}"	
			curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event=anwesend"
			daheim=1
		fi
		ncounter=1
    elif [ "$NUMOFLINES" != ${TAGS[a]} ]; then
		# Abwesend
		if [ "$ncounter" -lt "$away" ]; then
			echo "Counter Abwesend: " $ncounter
		fi
		
		if [ "$ncounter" == "$away" ]; then
			echo "Status: abwesend ${NAMES[a]}"
			curl "http://$homeeip:$homeeport/api/v2/webhook_trigger?webhooks_key=$webhooks_key&event=abwesend"
			daheim=0    
			ncounter=0
		fi
		ncounter=$[ncounter+ 1]
    else
        echo "noop"
    fi
    sleep 1
    done
done

exit 0

