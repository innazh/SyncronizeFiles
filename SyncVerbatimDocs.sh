#!/bin/bash
#IMPORTANT: works for newly created files, modified files, files to be deleted should have the word delete in them (doesnt accommodate for renamed files...(https://stackoverflow.com/questions/17789606/linux-unix-command-to-check-when-a-file-was-renamed)) 
#IMPORTANT2: file and folder names must contain no spaces. (figure this out pls)(might use commas instead of space as delimiter)
#This scripts will find analyze if there's any difference between these two Documents folders and make them identical again by
#picking the newer version of each file and copying it over to the other folder.
folder1="C:/Users/TheDream/Desktop/Documents"
folder2="E:/Documents"

function removeSpaces
{
	#Find all the files that have spaces in both folders and replace them with underscores
	find "$folder1" -type f -name "* *" | while read file; do mv "$file" ${file// /_}; done
	find "$folder2" -type f -name "* *" | while read file; do mv "$file" ${file// /_}; done	
}

#Searches for the files that have "d/Delete" in their name and deletes them as well as their copy in the other directory
function deleteFiles
{
	#find the paths of files that have the word D/delete in them
	to_be_deleted="$(find $folder1 $folder2 -type f -name "*[dD]elete*"  | tr '\r ' '\n' | tr '\r\n' ',' | sed 's/,$//')"
	echo "To be deleted: $to_be_deleted"
	read -p "$*"
	#Split the paths into different variables
	IFS=',' read -ra delete_array <<< "$to_be_deleted" 

	#Loop through the newly created array
	counter=1
	while [ $counter -le ${#delete_array[@]} ]
	do
		#identify paths:
		deletePath=${delete_array[counter-1]}
		
		#if file exists ->get it deleted, after -> extract the word [Dd]elete from it and delete that too (check if exists before doing so)
		if [ -e "$deletePath" ];
		then 
			rm -f "$deletePath"
			echo "File $deletePath has been removed."
			filenameToDelete="$(echo $deletePath | sed 's/[Dd]elete//' | grep -oE '[^/]+$')"
			
			#find the file under the same name in the other dir
			delete2="$(find "$folder1" -name "$filenameToDelete")"

			#if the variable is empty
			if [ -z "$delete2" ]
			then
			      delete2="$(find "$folder2" -name "$filenameToDelete")"
			      rm -f "$delete2"
				echo "File $delete2 has been removed."

			else
			      rm -f "$delete2"
				echo "File $delete2 has been removed."

			fi
		fi

		counter=$((counter+1))
	done
}

#Analyzes 2 folders. Finds the files that are only present in one of the folders -> copies them over to the other one. 
#If files are identical but modification dates are different -> replaces the older file with the one that was modified more recently. 
function updateFiles
{
	#Gets absolute paths of files that differ separated by comma (ps-last command deletes last comma if it's there)
	all_paths_string="$(diff -rqN $folder1 $folder2 | sed 's/Files // ; s/ and// ; s/ differ//' | tr '\r\n' ',' | tr '\r ' ',' | sed 's/,$//')"
	
	#Split the master string using comma delimiter and put it into the array
	IFS=',' read -ra paths_array <<< "$all_paths_string" 

	#Initialize all the flags
	counter=1
	flagC=false
	flagE=false

	while [ $counter -le ${#paths_array[@]} ]
	do
		#identify paths:
		pathToC=${paths_array[counter-1]}
		pathToE=${paths_array[counter]}
		
		#check if they're valid
		if [ -e "$pathToC" ]; 
		then
			echo "$pathToC is valid"
			dateC=$(date -r $pathToC "+%s")
			HumanDateC=$(date -r $pathToC)
			echo "Date c: " $HumanDateC
			echo "Date TimeStamp: " $dateC
		else
			echo "$pathToC is invalid"
			flagC=true
		fi
		
		if [ -e "$pathToE" ]; 
		then
			echo "$pathToE is valid"
			dateE=$(date -r $pathToE "+%s")
			HumanDateE=$(date -r $pathToE)
			echo "Date e: " $HumanDateE
			echo "Date eTimeStamp: " $dateE
		else
			echo "$pathToE is invalid"
			flagE=true
		fi
		
		#if both files exist -> compare the dates.
		if [ "$flagC" = false ] && [ "$flagE" = false ];
		then
			echo "Both paths are valid"
			echo "Comparing 'last modified' dates..."
			if [ "$dateC" -ge "$dateE" ]
			then
				#if pathC is more recent then copy it to pathE
				echo "Greater date: " $dateC
				echo "Greater date: $HumanDateC"
				echo "Copying $pathToC to $pathToE..."
				cp -f "$pathToC" "$pathToE"
			fi	
			if [ "$dateE" -ge "$dateC" ]
			then
				#if pathE is more recent then copy it to pathC
				echo "Greater date: " $dateE
				echo "Greater date: $HumanDateE"
				echo "Copying $pathToE to $pathToC..."
				cp -f "$pathToE" "$pathToC"
			fi
		elif [ "$flagC" = true ]
		then	
			filename="$(echo $pathToC | grep -oE '[^/]+$')"
			pathToC="$(echo $pathToC | sed -E 's/[^/]+$//')"
			mkdir -p "$pathToC" && cp "$pathToE" "$_" 
			echo "Directories $pathToC have been created and file $filename has been copied over."
		else
			filename="$(echo $pathToE | grep -oE '[^/]+$')"
			pathToE="$(echo $pathToE | sed -E 's/[^/]+$//')"
			mkdir -p "$pathToE" && cp "$pathToC" "$_"
			echo "Directories $pathToE have been created and file $filename has been copied over."
		fi
		
		counter=$((counter+2))
		#echo "counter has increased and is now: " $counter
		#read -p "$*"
	done
}

echo "Removing all the spaces in filenames"
removeSpaces
#FIRST: accommodate for files to be deleted
echo "Looking for files to be deleted..."
deleteFiles

#SECOND: accommodate for files to be that were modified or created
echo "Looking for files that were modified and created..."
updateFiles

read -n 1 -s -r -p "Press any key to continue"
