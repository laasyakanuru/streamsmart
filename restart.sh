#!/bin/bash

echo "🔄 Restarting StreamSmart..."
echo ""

./stop.sh
sleep 2
./start.sh

