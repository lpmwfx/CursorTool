#!/bin/bash

# Cursor Tools Installationsscript
# Installerer cursor_chat_cli og tools_ui

set -e  # Stop scriptet ved fejl

# Farver for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Cursor Tools Installation ===${NC}"
echo "Dette script installerer Cursor Chat værktøjet og UI."

# Tjek om Dart er installeret
if ! command -v dart &> /dev/null; then
    echo -e "${RED}Fejl: Dart SDK er ikke installeret.${NC}"
    echo "Installer Dart fra https://dart.dev/get-dart"
    exit 1
fi

# Tjek om Flutter er installeret (for UI)
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Advarsel: Flutter SDK er ikke installeret.${NC}"
    echo "Flutter er påkrævet for at køre UI-delen."
    echo "Installer Flutter fra https://flutter.dev/docs/get-started/install"
    echo "UI-delen vil ikke blive installeret."
    SKIP_UI=true
else 
    SKIP_UI=false
fi

# Opret installationsmapper
echo -e "${GREEN}Opretter installationsmapper...${NC}"
mkdir -p ~/.cursor

# Installer CLI-værktøjet
echo -e "${GREEN}Installerer CLI-værktøjet...${NC}"
cd cursor_chat_cli
dart pub get
echo "Kompilerer eksekverbar fil..."
dart compile exe bin/cursor_chat_tool.dart -o cursor_chat_tool
echo "Kopierer til ~/.cursor/..."
cp cursor_chat_tool ~/.cursor/
chmod +x ~/.cursor/cursor_chat_tool
ln -sf ~/.cursor/cursor_chat_tool ~/.cursor/cursorchat

# Tilføj til PATH hvis det ikke allerede er der
if ! grep -q "PATH=\"\$HOME/.cursor:\$PATH\"" ~/.bashrc; then
    echo -e "${GREEN}Tilføjer ~/.cursor til PATH i .bashrc...${NC}"
    echo -e '\n# Tilføj cursor_chat_tool til PATH\nexport PATH="$HOME/.cursor:$PATH"' >> ~/.bashrc
    echo "PATH opdateret. Kør 'source ~/.bashrc' for at aktivere det i den aktuelle shell."
else
    echo -e "${GREEN}~/.cursor er allerede i PATH.${NC}"
fi

cd ..

# Installer UI-appen hvis Flutter er installeret
if [ "$SKIP_UI" = false ]; then
    echo -e "${GREEN}Installerer UI-appen...${NC}"
    cd tools_ui
    flutter pub get
    
    # Byg til det aktuelle operativsystem
    echo -e "${GREEN}Bygger til dit operativsystem...${NC}"
    if [ "$(uname)" = "Linux" ]; then
        flutter build linux --release
        # Opret desktop-genvej for Linux
        echo -e "${GREEN}Opretter desktop-genvej...${NC}"
        mkdir -p ~/.local/share/applications
        cat > ~/.local/share/applications/cursor-tools.desktop << EOL
[Desktop Entry]
Name=Cursor Tools
Exec=${PWD}/build/linux/x64/release/bundle/cursor_tools_ui
Icon=${PWD}/assets/images/cursor_icon.png
Type=Application
Categories=Development;
EOL
        echo "Desktop-genvej oprettet."
    elif [ "$(uname)" = "Darwin" ]; then
        flutter build macos --release
        echo "macOS app bygget i ${PWD}/build/macos/Build/Products/Release/."
    else
        flutter build windows --release
        echo "Windows app bygget i ${PWD}/build/windows/runner/Release/."
    fi
    
    cd ..
fi

echo -e "${GREEN}Installation fuldført!${NC}"
echo ""
echo "Cursor Chat CLI kan nu køres med 'cursorchat' fra terminalen."
if [ "$SKIP_UI" = false ]; then
    echo "UI-appen er bygget og klar til brug."
    if [ "$(uname)" = "Linux" ]; then
        echo "Du kan starte UI-appen fra applikationsmenuen eller med:"
        echo "${PWD}/tools_ui/build/linux/x64/release/bundle/cursor_tools_ui"
    fi
fi
echo ""
echo -e "${YELLOW}Tak fordi du bruger Cursor Tools!${NC}" 