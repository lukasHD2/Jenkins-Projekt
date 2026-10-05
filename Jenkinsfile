pipeline {
    agent any

    stages {

        stage('Syntax Check') {
            steps {
                sh 'bash -n netwatch.sh'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t netwatch:${BUILD_NUMBER} .
                """
            }
        }

        stage('Create Latest Docker Image') {
            steps {
                sh """
                    docker tag \
                    netwatch:${BUILD_NUMBER} \
                    netwatch:latest
                """
            }
        }

        stage('Integration Test') {
            steps {
                sh '''
                    set -e

                    NETWORK="netwatch-test-network"
                    DB_CONTAINER="netwatch-test-db"
                    NETWATCH_CONTAINER="netwatch-test"

                    DB_NAME="netwatch"
                    DB_USER="netwatch"

                    echo "========================================"
                    echo " NetWatch Integration Test"
                    echo "========================================"

                    #
                    # Alte Testumgebung entfernen
                    #

                    echo "Entferne alte Testcontainer..."

                    docker rm -f "$NETWATCH_CONTAINER" 2>/dev/null || true
                    docker rm -f "$DB_CONTAINER" 2>/dev/null || true
                    docker network rm "$NETWORK" 2>/dev/null || true

                    #
                    # Test-Netzwerk erstellen
                    #

                    echo "Erstelle Docker Netzwerk..."

                    docker network create "$NETWORK"

                    #
                    # MariaDB starten
                    #

                    echo "Starte MariaDB..."

                    docker run -d \
                        --name "$DB_CONTAINER" \
                        --network "$NETWORK" \
                        -e MARIADB_ROOT_PASSWORD=rootpassword \
                        -e MARIADB_DATABASE="$DB_NAME" \
                        -e MARIADB_USER="$DB_USER" \
                        -e MARIADB_PASSWORD="$DB_PASSWORD" \
                        mariadb:latest

                    echo "MariaDB Container gestartet."

                    #
                    # Auf MariaDB warten
                    #

                    echo "Warte auf MariaDB..."

                    for i in $(seq 1 30); do

                        if docker exec "$DB_CONTAINER" \
                            mariadb \
                            -u"$DB_USER" \
                            -p"$DB_PASSWORD" \
                            -e "SELECT 1;" \
                            > /dev/null 2>&1
                        then
                            echo "MariaDB ist bereit."
                            break
                        fi

                        if [ "$i" -eq 30 ]; then
                            echo "FEHLER: MariaDB wurde nicht bereit."

                            docker logs "$DB_CONTAINER"

                            exit 1
                        fi

                        echo "MariaDB noch nicht bereit..."
                        sleep 2

                    done

                    #
                    # NetWatch starten
                    #

                    echo ""
                    echo "Starte NetWatch..."

                    docker run -d \
                        --name "$NETWATCH_CONTAINER" \
                        --network "$NETWORK" \
                        -e DB_HOST="$DB_CONTAINER" \
                        -e DB_PORT=3306 \
                        -e DB_NAME="$DB_NAME" \
                        -e DB_USER="$DB_USER" \
                        -e DB_PASSWORD="$DB_PASSWORD" \
                        netwatch:${BUILD_NUMBER}

                    echo "NetWatch Container gestartet."

                    #
                    # Prüfen ob NetWatch läuft
                    #

                    sleep 5

                    echo ""
                    echo "Prüfe NetWatch Container..."

                    if ! docker ps \
                        --filter "name=$NETWATCH_CONTAINER" \
                        --filter "status=running" \
                        --format '{{.Names}}' \
                        | grep -q "^$NETWATCH_CONTAINER\$"
                    then

                        echo "FEHLER: NetWatch läuft nicht!"

                        docker logs "$NETWATCH_CONTAINER"

                        exit 1
                    fi

                    echo "NetWatch läuft."

                    #
                    # Logs anzeigen
                    #

                    echo ""
                    echo "========================================"
                    echo " NetWatch Logs"
                    echo "========================================"

                    docker logs "$NETWATCH_CONTAINER"

                    #
                    # Prüfen ob Tabelle existiert
                    #

                    echo ""
                    echo "Prüfe Datenbank..."

                    docker exec "$DB_CONTAINER" \
                        mariadb \
                        -u"$DB_USER" \
                        -p"$DB_PASSWORD" \
                        "$DB_NAME" \
                        -e "SHOW TABLES;"

                    #
                    # Auf ersten Datensatz warten
                    #

                    echo ""
                    echo "Warte auf Ping-Ergebnis..."

                    RESULT_FOUND="false"

                    for i in $(seq 1 30); do

                        COUNT=$(docker exec "$DB_CONTAINER" \
                            mariadb \
                            -u"$DB_USER" \
                            -p"$DB_PASSWORD" \
                            "$DB_NAME" \
                            -N \
                            -e "SELECT COUNT(*) FROM ping_results;" \
                            2>/dev/null || echo "0")

                        echo "Anzahl Datensätze: $COUNT"

                        if [ "$COUNT" -gt 0 ]; then
                            RESULT_FOUND="true"
                            break
                        fi

                        sleep 2

                    done

                    #
                    # Ergebnis prüfen
                    #

                    if [ "$RESULT_FOUND" != "true" ]; then

                        echo ""
                        echo "FEHLER: Kein Ping-Ergebnis in der Datenbank!"

                        echo ""
                        echo "NetWatch Logs:"
                        docker logs "$NETWATCH_CONTAINER"

                        exit 1
                    fi

                    #
                    # Datensatz anzeigen
                    #

                    echo ""
                    echo "========================================"
                    echo " Ping-Ergebnis"
                    echo "========================================"

                    docker exec "$DB_CONTAINER" \
                        mariadb \
                        -u"$DB_USER" \
                        -p"$DB_PASSWORD" \
                        "$DB_NAME" \
                        -e "
                            SELECT
                                hostname,
                                ip_address,
                                checked_at,
                                status,
                                response_time_ms
                            FROM ping_results;
                        "

                    echo ""
                    echo "========================================"
                    echo " Integration Test erfolgreich"
                    echo "========================================"
                '''
            }

            post {
                always {
                    sh '''
                        echo ""
                        echo "========================================"
                        echo " Cleanup"
                        echo "========================================"

                        docker rm -f netwatch-test 2>/dev/null || true
                        docker rm -f netwatch-test-db 2>/dev/null || true
                        docker network rm netwatch-test-network 2>/dev/null || true

                        echo "Testumgebung entfernt."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline erfolgreich!'
        }

        failure {
            echo 'Pipeline fehlgeschlagen!'
        }
    }
}