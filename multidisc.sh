#!/bin/bash

read -p "Enter the full ROM path (example: /home/pi/RetroPie/roms/nes): " ROMPATH
read -p "Enter the file extension for the existing ROMs/images (example (ENTER ONE ONLY. NO LEADING PERIOD.)): nes zip chd): " EXTENSION

echo "ROM path is: " "$ROMPATH"
echo "File extension is: " "$EXTENSION"

# find any files (not directories) with filenames containing the provided specifications, list them if and only if the filename contains the expression "(Disc [1-9]", cut out some characters from each entry (ideally, the path to the file, edit each line that's returned to omit the string " (Disc [1-5].chd)", sort this list with and filter unique entries, copy the results into multidisc_games.txt.

# find /media/usb/roms/Sony\ PlayStation/*.chd -type f -exec ls -Q {} \; | grep "(Disc [1,2,3,4,5,6,7,8,9])" | cut -f 6 -d "/" | sed 's/ (Disc [1-9]).chd'// | sort -u | tee multidisc_games.txt | mkdir -p
# find /media/usb/roms/Sony\ PlayStation/*.chd -type f -exec ls {} \; | grep "(Disc [1-9])" | cut -f 6 -d "/" | sed 's/ (Disc [1-9]).chd'// | sort -u | tee multidisc_games.txt
find "$ROMPATH"/*."$EXTENSION" -type f -exec ls {} \; | grep "(Disc [1-9])" | cut -f 7 -d "/" | tee "$ROMPATH"/multidisc_game_files.txt | sed "s/ (Disc [1-9]).$EXTENSION"// | sort -u | tee "$ROMPATH"/multidisc_games.txt

# The intent here is to read each line from multidisc_games.txt as the variable GAMENAME, and for each instance, list all files containing GAMENAME within the filename, and output this list to GAMENAME.m3u.
# for GAMENAME in $(cat multidisc_games.txt)


#todo: prompt user for rompath and use rompath as the path argument for `find` (probably guide user to enter full path for flexibility, or use . for current directory)
#todo: move each file to subfolder multidisc_games after appending m3u files
#todo: backup Emulationstation gamelists and Attract Mode romlists - add date to each folder
#todo: generate gamelists for Emulationstation and Attract Mode.  Copy each to /home/pi/gamelists-romlists as well as the default directory for Emulationstation gamelists and Attract Mode romlists
#todo: figure out file extension flexibility
#todo: figure out how to cut to last field of /PATH/TO/FILE

mkdir "$ROMPATH"/multidisc_games

input="$ROMPATH"/multidisc_games.txt
while IFS= read -r LINE
do
	ls "$ROMPATH"/*\(Disc\ ?\)."$EXTENSION"  | grep "$LINE" >> "$ROMPATH"/"$LINE".m3u
done < "$input"

input="$ROMPATH"/multidisc_game_files.txt
while IFS= read -r LINE
do
	mv "$ROMPATH"/"$LINE" "$ROMPATH"/multidisc_games/
done < "$input"



rm "$ROMPATH"/multidisc_game*.txt

#todo: edit the rompath such that /home/pi/RetroPie/roms/ is built into the variable (user specifies only the last branch of the directory tree)
#todo: backup gamelists when this script is run (date+gamelists+backup or date+romlists directory+backup alongside the original in the same hierarchy level.
#todo: generate gamelists after multidisc roms/images are moved to multidisc_games
#todo: move roms/images from multidisc_games directory to original rom directory when gamelist is complete
#todo: remove empty multidisc_games directory after roms are returned to their original directory
#todo: test this script with rom directories that have subfolders (should be fine. verify)
#todo: set this script as a command in raspbian
#todo: add command line option to skip gamelist generation
#todo: directory selector / gui?
