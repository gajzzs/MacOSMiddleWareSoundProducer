#!/bin/bash

# demo_mode.sh - A simulation to showcase MacOSMiddleWareSoundProducer

# Function to set Terminal Title (Triggers app_activity sound)
set_title() {
    echo -n -e "\033]0;$1\007"
}

# Cleanup on exit
cleanup() {
    rm -f ~/Desktop/demo_hack_*.txt
    set_title "Demo Complete"
    echo ""
    echo "✅ Demo Complete. Cleaned up files."
}
trap cleanup EXIT

echo "🎬 Starting Middleware Sound Demo..."
echo "Make sure the SoundProducer app is running!"
sleep 2

neofetch

# 1. Simulate Typing / Processing (Title Changes)
echo ">>> PHASE 1: SYSTEM INFILTRATION (App Activity)"
for i in {1..5}; do
    set_title "CONNECTING_TO_MAINFRAME_V$i..."
    echo -n "encrypting..." 
    sleep 0.3
    set_title "BYPASSING_FIREWALL_LAYER_$i..."
    echo -n "bypassing..."
    sleep 0.3
done
echo ""

# 2. Simulate Network Activity (Triggers network_activity sound)
echo ">>> PHASE 2: DOWNLOADING PAYLOAD (Network Activity)"
set_title "DOWNLOADING_PAYLOAD..."
# Download a small file repeatedly to trigger network thresholds
for i in {1..3}; do
    curl -s "https://www.google.com" > /dev/null &
    curl -s "https://www.example.com" > /dev/null &
    sleep 0.5
    echo -n "."
done
wait
echo ""
sleep 1

# 3. Simulate Disk Activity (Triggers disk_write sound)
echo ">>> PHASE 3: WRITING TO DISK (Disk Activity)"
set_title "WRITING_ASSETS_TO_DISK..."
for i in {1..5}; do
    touch ~/Desktop/demo_hack_$i.txt
    echo "Hacked Content" > ~/Desktop/demo_hack_$i.txt
    sleep 0.2
    echo -n "💾"
done
echo ""
sleep 1

# 4. Simulate Window Management (Triggers window_open/close sound)
echo ">>> PHASE 4: GUI MANIPULATION (Window Events)"
set_title "LAUNCHING_DECOY..."
echo "Opening Calculator..."
open -a Calculator
sleep 2
echo "Closing Calculator..."
killall Calculator
sleep 1

# 5. Finale
set_title "ACCESS_GRANTED"
echo ">>> DEMO SEQUENCE COMPLETE."
echo "Hope you enjoyed the show! 🎵"
sleep 2
