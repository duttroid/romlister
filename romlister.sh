#!/bin/bash

# Prompt user to enter ROM directory and store the ROM path in $ROMPATH
read -p "Enter the full ROM path (example: /home/pi/RetroPie/roms/nes): " ROMPATH


# store the file extension in $EXTENSION
read -p "FOR MULTI-DISC ROMS/IMAGES: Enter the file extension for the existing ROMs/images. ENTER ONE ONLY. NO LEADING PERIOD. Example: nes zip chd: " EXTENSION


# Create $LISTDEST, the destination directory in which romlists and gamelists will be saved.
read -p "Enter the full path to the directory in which you want romlists/gamelists saved: " LISTDEST


# Confirm the $ROMPATH so the user has a hint of where to look in case they believe anything fucks up.
echo "ROM path is: " "$ROMPATH"


# Confirm the $EXTENSION so the user has a hint of where to look in case they believe anything fucks up.
echo "File extension is: " "$EXTENSION"


#store the system folder name in $SYSTEM.  This will be used to ensure correspondence with the correct rom folder.
SYSTEM=$(echo "$ROMPATH" | (rev | cut -f1 -d"/" | rev))
echo "System is: $SYSTEM"


# The romlist.txt and gamelist.xml files are going in $LISTDEST/$SYSTEM.  Create the directory.
mkdir -p "$LISTDEST"/"$SYSTEM"


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


#create gamelist.xml
echo "<?xml version=\"1.0\"?>" > "$LISTDEST"/"$SYSTEM"/gamelist.xml
echo "<gameList>" >> "$LISTDEST"/"$SYSTEM"/gamelist.xml


# define variables for Emulationstation gamelist.xml and store the appropriate strings for an xml in each variable.
#SYSTEM=$(echo "$ROMPATH" | (rev | cut -f1 -d"/" | rev))
input="$LISTDEST"/"$SYSTEM"/rom_list.txt
while IFS= read -r LINE
do
#todo: make these echo statements more efficient.  Should only take 1 echo statement, but I'm doing something wrong or getting thrown off by nano's syntax highlighitng right now.
#todo: be sure to handle ampersand and all special characters  correctly.  find and replace the & character with &amp; - can one find and replace using just the command line?
	echo "	<game>" >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "		<path>./$LINE<path>"  >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "		<name>$(echo $LINE | (rev | cut -f2- -d"." | rev))</name>"  >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "		<image>$(echo ./boxart/$LINE | (rev | cut -f2- -d"." | rev)).png</image>"  >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "		<marquee>$(echo ./wheel/$LINE | (rev | cut -f2- -d"." | rev)).png</marquee>"  >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "		<video>$(echo ./snap/$LINE | (rev | cut -f2- -d"." | rev)).png</video>"  >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
	echo "	</game>" >> "$LISTDEST"/"$SYSTEM"/gamelist.xml
done < "$input"

echo "</gamelist>" >> "$LISTDEST"/"$SYSTEM"/gamelist.xml


#Cleanup time
#remove rom_list_no_extensions.txt and rom_list.txt as they are no longer needed.

rm "$LISTDEST"/"$SYSTEM"/rom_list.txt
rm "$LISTDEST"/"$SYSTEM"/rom_list_no_extensions.txt
mv "$ROMPATH"/multidisc_games/* "$ROMPATH"
rm -d "$ROMPATH"/multidisc_games


#todo: generate gamelists for Emulationstation and Attract Mode.  Copy each to /home/pi/gamelists-romlists as well as the default directory for Emulationstation gamelists and Attract Mode romlists
#todo: backup gamelists when this script is run (date+gamelists+backup or date+romlists directory+backup alongside the original in the same hierarchy level).
#todo: set this script as a command in raspbian
#todo: add command line option to skip gamelist generation
#todo: directory selector / gui?
