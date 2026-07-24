#!/bin/bash

# NetRaven Text-to-Speech Module

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TTS_DIR="$HOME/.netraven/tts"
mkdir -p "$TTS_DIR"

check_tts_deps() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[!] python3 is required for TTS${NC}"
        return 1
    fi
    if ! python3 -c "import gtts" &> /dev/null; then
        echo -e "${YELLOW}[!] gTTS not installed. Installing...${NC}"
        pip3 install gtts --break-system-packages 2>/dev/null || {
            echo -e "${RED}[!] Failed to install gTTS. Run: pip3 install gtts --break-system-packages${NC}"
            return 1
        }
    fi
    if ! command -v mpg123 &> /dev/null && ! command -v ffplay &> /dev/null; then
        echo -e "${YELLOW}[!] No audio player found (mpg123 or ffplay). Install one for playback.${NC}"
    fi
    return 0
}

tts_text() {
    read -p "Enter text to convert: " text
    if [ -z "$text" ]; then
        echo -e "${RED}[!] No text provided${NC}"
        return
    fi
    read -p "Language code (default: en): " lang
    lang=${lang:-en}
    local outfile="$TTS_DIR/tts_$(date +%s).mp3"
    python3 -c "
from gtts import gTTS
tts = gTTS('''$text''', lang='$lang')
tts.save('$outfile')
" && echo -e "${GREEN}[+] Saved: $outfile${NC}" || echo -e "${RED}[-] TTS generation failed${NC}"
    if command -v mpg123 &> /dev/null; then
        read -p "Play now? (y/n): " play
        [ "$play" = "y" ] && mpg123 "$outfile"
    elif command -v ffplay &> /dev/null; then
        read -p "Play now? (y/n): " play
        [ "$play" = "y" ] && ffplay -autoexit -nodisp "$outfile"
    fi
}

tts_file() {
    read -p "Enter file path (.txt/.md/.php/.sh/.json/.xml/.yaml): " filepath
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo -e "${RED}[!] File not found${NC}"
        return
    fi
    local content
    content=$(head -c 5000 "$filepath")
    if [ "$(wc -c < "$filepath")" -gt 5000 ]; then
        echo -e "${YELLOW}[!] File truncated to 5000 characters for TTS${NC}"
    fi
    read -p "Language code (default: en): " lang
    lang=${lang:-en}
    local basename=$(basename "$filepath")
    local outfile="$TTS_DIR/${basename}.mp3"
    python3 -c "
from gtts import gTTS
tts = gTTS('''$content''', lang='$lang')
tts.save('$outfile')
" && echo -e "${GREEN}[+] Saved: $outfile${NC}" || echo -e "${RED}[-] TTS generation failed${NC}"
    if command -v mpg123 &> /dev/null; then
        read -p "Play now? (y/n): " play
        [ "$play" = "y" ] && mpg123 "$outfile"
    elif command -v ffplay &> /dev/null; then
        read -p "Play now? (y/n): " play
        [ "$play" = "y" ] && ffplay -autoexit -nodisp "$outfile"
    fi
}

list_mp3s() {
    log "TTS MP3 Files"
    if [ -d "$TTS_DIR" ]; then
        local count=0
        for f in "$TTS_DIR"/*.mp3; do
            if [ -f "$f" ]; then
                echo -e "${CYAN}---${NC} $(basename "$f") ($(du -h "$f" | cut -f1))"
                count=$((count + 1))
            fi
        done
        if [ $count -eq 0 ]; then
            echo -e "${YELLOW}No MP3 files generated yet${NC}"
        else
            echo -e "${GREEN}Total: $count file(s)${NC}"
        fi
    fi
}

play_mp3() {
    read -p "Enter MP3 filename: " mp3file
    local path="$TTS_DIR/$mp3file"
    if [ ! -f "$path" ]; then
        path="$mp3file"
        if [ ! -f "$path" ]; then
            echo -e "${RED}[!] File not found${NC}"
            return
        fi
    fi
    if command -v mpg123 &> /dev/null; then
        mpg123 "$path"
    elif command -v ffplay &> /dev/null; then
        ffplay -autoexit -nodisp "$path"
    else
        echo -e "${RED}[!] No audio player available (install mpg123 or ffplay)${NC}"
    fi
}

delete_mp3() {
    read -p "Enter MP3 filename to delete: " mp3file
    local path="$TTS_DIR/$mp3file"
    if [ -f "$path" ]; then
        rm -f "$path"
        echo -e "${GREEN}[+] Deleted: $mp3file${NC}"
    else
        echo -e "${RED}[!] File not found${NC}"
    fi
}

tts_menu() {
    check_tts_deps || return
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Text-to-Speech${NC}                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  TTS from Text                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  TTS from File                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  List MP3s                            ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  Play MP3                             ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Delete MP3                           ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                    ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
        echo
        read -p "Select option: " opt
        case $opt in
            1) tts_text ;;
            2) tts_file ;;
            3) list_mp3s ;;
            4) play_mp3 ;;
            5) delete_mp3 ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}
