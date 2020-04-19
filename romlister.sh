#!/bin/bash

# ROM directory is stored in $ROMPATH
ROMPATH="/home/pi/RetroPie/roms"


# Prompt user to enter the system folder name (/home/pi/RetroPie/roms) is already set as $ROMPATH
read -p "What is the system folder name (exactly as it appears in /home/pi/RetroPie/roms/)? " SYSTEM
echo "System is: $SYSTEM"


# store the file extension in $EXTENSION
read -p "ONLY FOR MULTI-DISC ROMS/IMAGES: Enter the file extension for the existing ROMs/images. ENTER ONE ONLY. NO LEADING PERIOD. Examples: nes | zip | chd: " EXTENSION


# If there are multi-disc titles, what's the identifier in the filename? Examples: Disc, Disk, Tape, Side?
read -p "ONLY FOR MULTIDISC ROMS/IMAGES: Enter the type of media that's designated in the filenames. Examples: Disc | Disk | Tape | Side: " MEDIA



# Create $LISTDEST, the destination directory in which romlists and gamelists will be saved.
# read -p "Enter the full path to the directory in which you want romlists/gamelists saved: " LISTDEST


# create $ROMLISTDIR to help save romlist.txt in /opt/retropie/configs/all/attractmode/romlists
ROMLISTDIR="/opt/retropie/configs/all/attractmode/romlists"

# Confirm the $ROMPATH so the user has a hint of where to look in case they believe anything fucks up.
echo "ROM path is: " "$ROMPATH/$SYSTEM"


# Confirm the $EXTENSION so the user has a hint of where to look in case they believe anything fucks up.
echo "File extension is: " "$EXTENSION"


# Store the system folder name in $SYSTEM.  This will be used to ensure correspondence with the correct rom folder.
#SYSTEM=$(echo "$ROMPATH" | (rev | cut -f1 -d"/" | rev))


# create $GAMELISTDIR to help save gamelist.xml in /home/pi/.emulationstation/gamelists/$SYSTEM/
GAMELISTDIR="/home/pi/.emulationstation/gamelists"


# make a backup of gamelist.xml and $SYSTEM.txt with date
cp "$GAMELISTDIR/$SYSTEM/gamelist.xml" "$GAMELISTDIR/$SYSTEM/gamelist.xml_backup_$(date +'%Y-%m-%d_%H:%M:%S')"
cp "$ROMLISTDIR/$SYSTEM.txt" "$ROMLISTDIR/$SYSTEM.txt_backup_$(date +'%Y-%m-%d_%H:%M:%S')"


# if any .m3u files exist, put them in this directory.


# The gamelist.xml files is going in $LISTDEST/$SYSTEM.  Create the directory.
mkdir -p "$GAMELISTDIR"/"$SYSTEM"



# Find any files (not directories) with filenames containing the provided specifications, list them if and only if the filename contains the expression "($MEDIA [1-9]",
# cut (by field) all directories in the path except for the ROM/image file name, save this filename in the list multidisc_game_files.txt,
# Stream edit the listing to remove,  " ($MEDIA [1-9].chd)", sort this list and filter unique entries, copy the results into multidisc_games.txt.
find "$ROMPATH"/"$SYSTEM" -maxdepth 1 -name "*.$EXTENSION" -type f -exec ls {} \; | grep "($MEDIA [1-9])" | (rev | cut -f1 -d"/" | rev) | tee "$ROMPATH"/"$SYSTEM"/multidisc_game_files.txt | sed "s/ ($MEDIA [1-9]).$EXTENSION"// | sort -u | tee "$ROMPATH"/"$SYSTEM"/multidisc_games.txt


# Make folder multidisc_games inside $ROMPATH.  All multidisc games get moved here.
mkdir "$ROMPATH"/"$SYSTEM"/multidisc_games


# Generate /.m3u files for each game.  Read the file multidisc_games.txt.  List and grep each line of multidisc_game_files.txt in $ROMPATH,
# and add each entry into an m3u file named after the current line ($LINE).
input="$ROMPATH"/"$SYSTEM"/multidisc_games.txt
while IFS= read -r LINE
do
	ls "$ROMPATH"/"$SYSTEM"/*\("$MEDIA"\ ?\)."$EXTENSION"  | grep "$LINE" | (rev | cut -f1 -d"/" | rev) >> "$ROMPATH"/"$SYSTEM"/"$LINE".m3u
done < "$input"


# Read multidisc_game_files.txt. Each entry corresponds to a file in the ROM directory.  Move each file to /multidsic_games.
# This will help to ensure that only any .m3u files are populated for multi-disc games.
input="$ROMPATH"/"$SYSTEM"/multidisc_game_files.txt
while IFS= read -r LINE
do
	mv "$ROMPATH"/"$SYSTEM"/"$LINE" "$ROMPATH"/"$SYSTEM"/multidisc_games/
done < "$input"


# Remove the multidisc_game_files.txt and multidisc_games.txt files, as they are no longer needed.
rm "$ROMPATH"/"$SYSTEM"/multidisc_game*.txt


# Find all files (non-recursive) in $ROMPATH, list them, drop the path, sort it, add each file to rom_list.txt for reference in creation of gamelist.txt file for Emulationstation.
# Then, remove the file extension to just list the rom names without extensions in rom_list_no_extensions.txt for reference in creation of romlist.txt file for Attract Mode.
find "$ROMPATH"/"$SYSTEM" -maxdepth 1 -type f -exec ls {} \; | (rev | cut -f1 -d"/" | rev) | sort -u | tee "$GAMELISTDIR"/"$SYSTEM"/rom_list.txt | (rev | cut -f2- -d"." | rev) | tee "$ROMLISTDIR"/rom_list_no_extensions.txt


# create $SYSTEM.txt for use with Attract Mode
echo "#Name;Title;Emulator;CloneOf;Year;Manufacturer;Category;Players;Rotation;Control;Status;DisplayCount;DisplayType;AltRomname;AltTitle;Extra;Buttons" > "$ROMLISTDIR"/"$SYSTEM.txt"


# read rom_list_no_extensions.txt and populate $SYSTEM.txt for use with Attract Mode.
input="$ROMLISTDIR"/rom_list_no_extensions.txt
while IFS= read -r LINE
do
	echo "$LINE;$LINE;$SYSTEM;;;;;;;;;;;;;;" >> "$ROMLISTDIR"/"$SYSTEM.txt"
done < "$input"


# create gamelist.xml
echo "<?xml version=\"1.0\"?>" > "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
echo "<gameList>" >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml


# replace XML character entities in rom_list.txt which will be read and used to generate gamelist.xml.  
# We don't use sed directly on gamelist.xml because in an XML, character entities that already exist must remain intact.
sed -i "s/\&/\&amp;/;s/>/\&gt;/;s/</\&lt;/;s/'/\&apos;/;s/\"/\&quot;/" "$GAMELISTDIR"/"$SYSTEM"/rom_list.txt


# define variables for Emulationstation gamelist.xml and store the appropriate strings for an xml in each variable.
input="$GAMELISTDIR"/"$SYSTEM"/rom_list.txt
while IFS= read -r LINE
do
#todo: make these echo statements more efficient.  Should only take 1 echo statement, but I'm doing something wrong or getting thrown off by nano's syntax highlighitng right now.
	echo "	<game>" >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "		<path>./$LINE</path>"  >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "		<name>$(echo $LINE | (rev | cut -f2- -d"." | rev))</name>"  >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "		<image>$(echo ./boxart/$LINE | (rev | cut -f2- -d"." | rev)).png</image>"  >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "		<marquee>$(echo ./wheel/$LINE | (rev | cut -f2- -d"." | rev)).png</marquee>"  >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "		<video>$(echo ./snap/$LINE | (rev | cut -f2- -d"." | rev)).mp4</video>"  >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
	echo "	</game>" >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml
done < "$input"


#The final line of gamelist.xml
echo "</gameList>" >> "$GAMELISTDIR"/"$SYSTEM"/gamelist.xml


#Cleanup time
#remove rom_list_no_extensions.txt and rom_list.txt as they are no longer needed.
rm "$GAMELISTDIR"/"$SYSTEM"/rom_list.txt
rm "$ROMLISTDIR"/rom_list_no_extensions.txt
mv "$ROMPATH"/"$SYSTEM"/multidisc_games/* "$ROMPATH"/"$SYSTEM"
rm -d "$ROMPATH"/"$SYSTEM"/multidisc_games


#to set this script as a command in raspbian, `sudo cp romlister.sh /usr/bin/romlister`
#todo: add command line option to skip gamelist generation?  Maybe.  Just copy/edit the script for now.
#todo: directory selector / gui?  Maybe someday.
