#!/bin/bash

# AI Performance Demo - Showcases sound middleware with dramatic effect
# Make this script executable: chmod +x ai_performance.sh

# Colors for visual impact
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Work directory
WORK_DIR=~/Desktop/ai_workspace
DEMO_FILE="$WORK_DIR/neural_data.txt"

# Function to set Terminal Title (Triggers app_activity)
set_title() {
    echo -n -e "\033]0;$1\007"
}

# Function to type effect
type_effect() {
    local text="$1"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep 0.02
    done
    echo ""
}

# Cleanup function
cleanup() {
    echo -e "\n${CYAN}🧹 Cleaning up workspace...${NC}"
    rm -rf "$WORK_DIR"
    set_title "AI Performance Complete"
    echo -e "${GREEN}✨ Performance Complete${NC}"
}
trap cleanup EXIT

clear
echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   AI PERFORMANCE MODE - SOUND DEMO    ║${NC}"
echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo ""
sleep 1.5

# ============================================
# PHASE 1: INITIALIZATION
# ============================================
echo -e "${CYAN}>>> PHASE 1: SYSTEM INITIALIZATION${NC}"
set_title "INITIALIZING_NEURAL_CORE..."

mkdir -p "$WORK_DIR"
sleep 0.3

type_effect "Loading cognitive modules..."
for i in {1..8}; do
    echo "module_$i.dat" > "$WORK_DIR/module_$i.txt"
    echo -n "▓"
    sleep 0.15
done
echo -e " ${GREEN}✓${NC}"
sleep 0.5

# ============================================
# PHASE 2: Network PROCESSING
# ============================================
echo -e "\n${BLUE}>>> PHASE 2: NETWORK PROCESSING${NC}"
set_title "PROCESSING_NETWORK_DATA..."


urls=(
    "https://www.google.com"
    "https://www.example.com"
    "https://www.apple.com"
    "https://www.github.com"
    "https://www.stackoverflow.com"
)

for url in "${urls[@]}"; do
    echo $url
    curl -s $url
    sleep 0.5
done
wait
sleep 1


# ============================================
# PHASE 3: DATA PROCESSING
# ============================================
echo -e "\n${BLUE}>>> PHASE 3: PROCESSING NEURAL DATA${NC}"
set_title "PROCESSING_QUANTUM_LAYERS..."

type_effect "Generating training datasets..."
for i in {1..15}; do
    # Write varied content to trigger disk activity
    echo "Neuron Layer $i: $(openssl rand -hex 32)" >> "$DEMO_FILE"
    sleep 0.1
    echo -n "⚡"
done
echo -e " ${GREEN}✓${NC}"
sleep 0.5

type_effect "Compressing neural weights..."
tar -czf "$WORK_DIR/weights.tar.gz" "$WORK_DIR"/*.txt 2>/dev/null
echo -e "  ${GREEN}✓ Compression complete${NC}"
sleep 0.5

# ============================================
# PHASE 4: MEMORY OPERATIONS
# ============================================
echo -e "\n${PURPLE}>>> PHASE 4: MEMORY CONSOLIDATION${NC}"
set_title "CONSOLIDATING_MEMORIES..."

type_effect "Reading memory blocks..."
for i in {1..8}; do
    cat "$WORK_DIR/module_$i.txt" > /dev/null
    echo -n "🧠"
    sleep 0.12
done
echo -e " ${GREEN}✓${NC}"
sleep 0.3

type_effect "Shuffling memory locations..."
for i in {1..5}; do
    mv "$WORK_DIR/module_$i.txt" "$WORK_DIR/mem_block_$i.txt"
    sleep 0.15
    echo -n "↔️ "
done
echo -e "${GREEN}✓${NC}"
sleep 0.5

# ============================================
# PHASE 5: WINDOW MANAGEMENT (VISUAL OUTPUTS)
# ============================================
echo -e "\n${CYAN}>>> PHASE 5: VISUALIZING RESULTS${NC}"
set_title "RENDERING_VISUAL_OUTPUT..."

type_effect "Opening visualization interfaces..."
sleep 0.5

# Open and close apps to trigger window sounds
apps=("Calculator" "TextEdit" "Notes")
for app in "${apps[@]}"; do
    echo -e "  🪟 Launching $app..."
    open -a "$app" 2>/dev/null
    sleep 1.2
    echo -e "  ❌ Closing $app..."
    killall "$app" 2>/dev/null
    sleep 0.8
done

# ============================================
# PHASE 6: INTENSIVE COMPUTATION
# ============================================
echo -e "\n${RED}>>> PHASE 6: DEEP COMPUTATION${NC}"
set_title "CALCULATING_QUANTUM_PROBABILITIES..."

type_effect "Running parallel computations..."
for i in {1..10}; do
    # CPU intensive operation
    echo "scale=1000; 4*a(1)" | bc -l > "$WORK_DIR/pi_$i.txt" &
    sleep 0.2
    echo -n "🔥"
done
wait
echo -e " ${GREEN}✓${NC}"
sleep 0.5

# ============================================
# PHASE 7: FILE SYSTEM CHOREOGRAPHY
# ============================================
echo -e "\n${YELLOW}>>> PHASE 7: ORGANIZING OUTPUTS${NC}"
set_title "ORGANIZING_FILE_SYSTEM..."

type_effect "Creating directory structure..."
mkdir -p "$WORK_DIR"/{logs,cache,models,results}
sleep 0.3

type_effect "Distributing files..."
for i in {1..5}; do
    echo "Result $i" > "$WORK_DIR/results/output_$i.txt"
    sleep 0.1
    echo "Log $i" > "$WORK_DIR/logs/log_$i.txt"
    sleep 0.1
    echo -n "📁"
done
echo -e " ${GREEN}✓${NC}"
sleep 0.5

# ============================================
# PHASE 8: NETWORK SYNC
# ============================================
echo -e "\n${PURPLE}>>> PHASE 8: SYNCHRONIZING STATE${NC}"
set_title "SYNCING_TO_CLOUD..."

type_effect "Uploading results to remote..."
for i in {1..6}; do
    curl -s "https://www.example.com" > /dev/null &
    sleep 0.3
    echo -n "☁️ "
done
wait
echo -e "${GREEN}✓${NC}"
sleep 0.5

# ============================================
# PHASE 9: RAPID FILE OPERATIONS
# ============================================
echo -e "\n${CYAN}>>> PHASE 9: FINALIZING ARTIFACTS${NC}"
set_title "GENERATING_ARTIFACTS..."

type_effect "Rapid data generation sequence..."
for i in {1..20}; do
    echo "Artifact $i: $(date +%s%N)" > "$WORK_DIR/artifact_$i.txt"
    sleep 0.05
done
echo -e "${GREEN}✓ Generated 20 artifacts${NC}"
sleep 0.3

type_effect "Batch reading artifacts..."
for i in {1..20}; do
    cat "$WORK_DIR/artifact_$i.txt" > /dev/null
    sleep 0.03
done
echo -e "${GREEN}✓ Verified all artifacts${NC}"
sleep 0.5

# ============================================
# PHASE 10: CLEANUP SEQUENCE
# ============================================
echo -e "\n${RED}>>> PHASE 10: CLEANUP PROTOCOL${NC}"
set_title "REMOVING_TRACES..."

type_effect "Erasing temporary files..."
rm -f "$WORK_DIR"/artifact_*.txt
rm -f "$WORK_DIR"/pi_*.txt
sleep 0.5

# ============================================
# FINALE
# ============================================
set_title "AI_PERFORMANCE_COMPLETE"
echo ""
echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║     🎭 PERFORMANCE COMPLETE 🎭        ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✨ All sound events triggered successfully${NC}"
echo -e "${CYAN}📊 Operations performed:${NC}"
echo -e "   • File writes: ~60"
echo -e "   • File reads: ~30"
echo -e "   • Network requests: ~10"
echo -e "   • Window events: ~6"
echo -e "   • Title changes: ~15"
echo ""
sleep 2
