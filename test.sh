#!/bin/bash

set -e

EXPECTED="ONLINE"

echo "================================"
echo " NetWatch Funktionstest"
echo "================================"

ACTUAL=$(./netwatch.sh --once 2>&1)

echo "$ACTUAL"

if echo "$ACTUAL" | grep -q "Status:        $EXPECTED"; then
    echo ""
    echo "TEST OK"
    exit 0
else
    echo ""
    echo "TEST FEHLGESCHLAGEN"
    echo "Erwarteter Status: $EXPECTED"
    echo "Tatsächliche Ausgabe:"
    echo "$ACTUAL"
    exit 1
fi
