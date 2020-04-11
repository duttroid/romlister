#!/bin/bash

# Prompt user to enter ROM directory
read -p "Enter the full ROM path (example: /home/pi/RetroPie/roms/nes): " ROMPATH

read -p "Enter the file extension for the existing ROMs/images (example (ENTER ONE ONLY. NO LEADING PERIOD.)): nes zip chd): " EXTENSION

echo "ROM path is: " "$ROMPATH"
echo "File extension is: " "$EXTENSION"

# find any files (not directories) with filenames containing the provided specifications, list them if and only if the filename contains the expression "(Disc [1-9]",
# cut (by field) all directories in the path except for the ROM/image file name, save this filename in the list multidisc_game_files.txt,
# Stream edit the listing to remove,  " (Disc [1-9].chd)", sort this list and filter unique entries, copy the results into multidisc_games.txt.

find "$ROMPATH" -maxdepth 1 -name "*.$EXTENSION" -type f -exec ls {} \; | grep "(Disc [1-9])" | (rev | cut -f1 -d"/" | rev) | tee "$ROMPATH"/multidisc_game_files.txt | sed "s/ (Disc [1-9]).$EXTENSION"// | sort -u | tee "$ROMPATH"/multidisc_games.txt

# todo: generate gamelists for Emulationstation and Attract Mode.  Copy each to /home/pi/gamelists-romlists as well as the default directory for Emulationstation gamelists and Attract Mode romlists
# todo: figure out file extension flexibility

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

#todo: edit the rompath such that /home/pi/RetroPie/roms/ is built into the variable (user specifies only the last branch of the directory tree)
#todo: backup gamelists when this script is run (date+gamelists+backup or date+romlists directory+backup alongside the original in the same hierarchy level).
#todo: generate gamelists after multidisc roms/images are moved to multidisc_games
#todo: move roms/images from multidisc_games directory to original rom directory when gamelist is complete
#todo: remove empty multidisc_games directory after roms are returned to their original directory
#todo: test this script with rom directories that have subfolders (should be fine. verify)
#todo: set this script as a command in raspbian
#todo: add command line option to skip gamelist generation
#todo: directory selector / gui?
