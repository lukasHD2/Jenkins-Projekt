#!/bin/bash

TARGETS_FILE="targets.conf"

DB_HOST="${DB_HOST:-mariadb}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-netwatch}"
DB_USER="${DB_USER:-netwatch}"
DB_PASSWORD="${DB_PASSWORD:-secret}"

echo "========================================"
echo " NetWatch startet"
echo "========================================"
echo "Datenbank: $DB_HOST:$DB_PORT"
echo "Database:  $DB_NAME"
echo ""

#
# Auf MariaDB warten
#
echo "Warte auf MariaDB..."

until mariadb \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    -e "SELECT 1;" \
    > /dev/null 2>&1
do
    echo "MariaDB noch nicht erreichbar..."
    sleep 2
done

echo "MariaDB ist erreichbar."

#
# Datenbank erstellen
#
echo "Prüfe Datenbank..."

mariadb \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    -e "
        CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
    "

echo "Datenbank '$DB_NAME' ist vorhanden."

#
# Tabelle erstellen
#
echo "Prüfe Tabelle..."

mariadb \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    "$DB_NAME" \
    -e "
        CREATE TABLE IF NOT EXISTS ping_results (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255) NOT NULL,
            ip_address VARCHAR(45) NOT NULL,
            checked_at DATETIME NOT NULL,
            status VARCHAR(20) NOT NULL,
            response_time_ms DECIMAL(10,3) NULL,

            INDEX idx_hostname (hostname),
            INDEX idx_checked_at (checked_at),
            INDEX idx_status (status)
        );
    "

echo "Tabelle 'ping_results' ist vorhanden."
echo ""

#
# Hauptschleife
#
while true; do

    while IFS=';' read -r HOSTNAME IP_ADDRESS; do

        # Leerzeichen entfernen
        HOSTNAME=$(echo "$HOSTNAME" | xargs)
        IP_ADDRESS=$(echo "$IP_ADDRESS" | xargs)

        # Leere Zeilen überspringen
        [ -z "$HOSTNAME" ] && continue

        # Kommentare überspringen
        [[ "$HOSTNAME" =~ ^# ]] && continue

        CHECK_TIME=$(date '+%Y-%m-%d %H:%M:%S')

        RESULT=$(ping -c 1 -W 2 "$IP_ADDRESS" 2>/dev/null)

        if echo "$RESULT" | grep -q "time="; then

            STATUS="ONLINE"

            RESPONSE_TIME=$(echo "$RESULT" \
                | sed -n 's/.*time=\([0-9.]*\).*/\1/p')

        else

            STATUS="OFFLINE"
            RESPONSE_TIME=""

        fi

        echo "----------------------------------------"
        echo "Hostname:      $HOSTNAME"
        echo "IP-Adresse:    $IP_ADDRESS"
        echo "Prüfzeitpunkt: $CHECK_TIME"
        echo "Status:        $STATUS"
        echo "Antwortzeit:   ${RESPONSE_TIME:-"-"} ms"

        #
        # Datenbank INSERT
        #

        if [ -n "$RESPONSE_TIME" ]; then

            mariadb \
                -h "$DB_HOST" \
                -P "$DB_PORT" \
                -u "$DB_USER" \
                -p"$DB_PASSWORD" \
                "$DB_NAME" \
                -e "
                    INSERT INTO ping_results
                    (
                        hostname,
                        ip_address,
                        checked_at,
                        status,
                        response_time_ms
                    )
                    VALUES
                    (
                        '$HOSTNAME',
                        '$IP_ADDRESS',
                        '$CHECK_TIME',
                        '$STATUS',
                        $RESPONSE_TIME
                    );
                "

        else

            mariadb \
                -h "$DB_HOST" \
                -P "$DB_PORT" \
                -u "$DB_USER" \
                -p"$DB_PASSWORD" \
                "$DB_NAME" \
                -e "
                    INSERT INTO ping_results
                    (
                        hostname,
                        ip_address,
                        checked_at,
                        status,
                        response_time_ms
                    )
                    VALUES
                    (
                        '$HOSTNAME',
                        '$IP_ADDRESS',
                        '$CHECK_TIME',
                        '$STATUS',
                        NULL
                    );
                "

        fi

        if [ $? -eq 0 ]; then
            echo "Datenbank:    gespeichert"
        else
            echo "Datenbank:    FEHLER beim Speichern"
        fi

    done < "$TARGETS_FILE"

    echo ""
    echo "Nächster Check in 60 Sekunden..."
    echo ""

    sleep 60

done
