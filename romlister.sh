#!/bin/bash

# Prompt user to enter ROM directory

#store the ROM path in $ROMPATH
read -p "Enter the full ROM path (example: /home/pi/RetroPie/roms/nes): " ROMPATH


#store the file extension in $EXTENSION
read -p "FOR MULTI-DISC ROMS/IMAGES: Enter the file extension for the existing ROMs/images. ENTER ONE ONLY. NO LEADING PERIOD. Example: nes zip chd: " EXTENSION

read -p "Enter the full path to the directory in which you want romlists/gamelists saved: " LISTDEST

echo "ROM path is: " "$ROMPATH"

echo "File extension is: " "$EXTENSION"


#store the system folder name in $SYSTEM.  This will be used to ensure correspondence with the correct rom folder.
SYSTEM=$(echo "$ROMPATH" | (rev | cut -f1 -d"/" | rev))
echo "System is: $SYSTEM"


# find any files (not directories) with filenames containing the provided specifications, list them if and only if the filename contains the expression "(Disc [1-9]",
# cut (by field) all directories in the path except for the ROM/image file name, save this filename in the list multidisc_game_files.txt,
# Stream edit the listing to remove,  " (Disc [1-9].chd)", sort this list and filter unique entries, copy the results into multidisc_games.txt.

find "$ROMPATH" -maxdepth 1 -name "*.$EXTENSION" -type f -exec ls {} \; | grep "(Disc [1-9])" | (rev | cut -f1 -d"/" | rev) | tee "$ROMPATH"/multidisc_game_files.txt | sed "s/ (Disc [1-9]).$EXTENSION"// | sort -u | tee "$ROMPATH"/multidisc_games.txt


# Make folder multidisc_games inside $ROMPATH.  All multidisc games get moved here.

mkdir "$ROMPATH"/multidisc_games


# Generate /.m3u files for each game.  Read the file multidisc_games.txt.  List and grep each line of multidisc_game_files.txt in $ROMPATH,
# and add each entry into an m3u file named after the current line ($LINE).
input="$ROMPATH"/multidisc_games.txt
while IFS= read -r LINE
do
	ls "$ROMPATH"/*\(Disc\ ?\)."$EXTENSION"  | grep "$LINE" >> "$ROMPATH"/"$LINE".m3u
done < "$input"


# Read multidisc_game_files.txt. Each entry corresponds to a file in the ROM directory.  Move each file to /multidsic_games.
# This will help to ensure that only any .m3u files are populated for multi-disc games.
input="$ROMPATH"/multidisc_game_files.txt
while IFS= read -r LINE
do
	mv "$ROMPATH"/"$LINE" "$ROMPATH"/multidisc_games/
done < "$input"


# Remove the multidisc_game_files.txt and multidisc_games.txt files, as they are no longer needed.
rm "$ROMPATH"/multidisc_game*.txt


# The romlist.txt and gamelist.xml files are going in $LISTDEST/SYSTEM.  Create the directory.
mkdir -p "$LISTDEST"/"$SYSTEM"

# Find all files (non-recursive) in $ROMPATH, list them, drop the path, sort it, add each file to rom_list.txt for reference in creation of gamelist.txt file for Emulationstation.
# Then, remove the file extension to just list the rom names without extensions in rom_list_no_extensions.txt for reference in creation of romlist.txt file for Attract Mode.
find "$ROMPATH" -maxdepth 1 -type f -exec ls {} \; | (rev | cut -f1 -d"/" | rev) | sort -u | tee "$LISTDEST"/"$SYSTEM"/rom_list.txt | (rev | cut -f2- -d"." | rev) | tee "$LISTDEST"/"$SYSTEM"/rom_list_no_extensions.txt


# create romlist.txt for use with Attract Mode
echo "#Name;Title;Emulator;CloneOf;Year;Manufacturer;Category;Players;Rotation;Control;Status;DisplayCount;DisplayType;AltRomname;AltTitle;Extra;Buttons" > "$LISTDEST"/"$SYSTEM"/romlist.txt

# read rom_list_no_extensions.txt and populate romlist.txt for use with Attract Mode.
input="$LISTDEST"/"$SYSTEM"/rom_list_no_extensions.txt
while IFS= read -r LINE
do
	echo "$LINE;$LINE;$SYSTEM;;;;;;;;;;;;;;" >> "$LISTDEST"/"$SYSTEM"/romlist.txt
done < "$input"

# read external file and populate gamelist.txt for use with Emulation Station.
#input="$LISTDEST"/"$SYSTEM"/rom_list.txt
#while IFS= read -r LINE
#do
#	echo #xml setup here
#done < "$input"


#Cleanup time
#remove rom_list_no_extensions.txt and rom_list.txt as they are no longer needed.

rm "$LISTDEST"/"$SYSTEM"/rom_list.txt
rm "$LISTDEST"/"$SYSTEM"/rom_list_no_extensions.txt
mv "$ROMPATH"/multidisc_games/* "$ROMPATH"
rm -d "$ROMPATH"/multidisc_games


#todo: test again with subfolders
#todo: fix errors generating Attract Mode romlist.txt
#todo: generate gamelists for Emulationstation and Attract Mode.  Copy each to /home/pi/gamelists-romlists as well as the default directory for Emulationstation gamelists and Attract Mode romlists
#todo: backup gamelists when this script is run (date+gamelists+backup or date+romlists directory+backup alongside the original in the same hierarchy level).
#todo: generate gamelists after multidisc roms/images are moved to multidisc_games
#todo: move roms/images from multidisc_games directory to original rom directory when gamelist is complete
#todo: remove empty multidisc_games directory after roms are returned to their original directory
#todo: set this script as a command in raspbian
#todo: add command line option to skip gamelist generation
#todo: directory selector / gui?
