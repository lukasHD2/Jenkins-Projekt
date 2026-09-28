#!/bin/bash

TARGETS_FILE="targets.conf"

while true; do

    while IFS=';' read -r HOSTNAME IP_ADDRESS; do
        # Leere Zeilen überspringen
        [ -z "$HOSTNAME" ] && continue

        CHECK_TIME=$(date '+%Y-%m-%d %H:%M:%S')

        RESULT=$(ping -c 1 -W 2 "$IP_ADDRESS" 2>/dev/null)

        if echo "$RESULT" | grep -q "time="; then
            STATUS="ONLINE"

            RESPONSE_TIME=$(echo "$RESULT" \
                | sed -n 's/.*time=\([0-9.]*\).*/\1/p')
        else
            STATUS="OFFLINE"
            RESPONSE_TIME="-"
        fi

        echo "----------------------------------------"
        echo "Hostname:     $HOSTNAME"
        echo "IP-Adresse:   $IP_ADDRESS"
        echo "Prüfzeitpunkt: $CHECK_TIME"
        echo "Status:       $STATUS"
        echo "Antwortzeit:  ${RESPONSE_TIME} ms"
    done < "$TARGETS_FILE"

    sleep 60
done
