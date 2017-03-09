#!/bin/bash

###################################################################
# BibTex-database generator
###################################################################

#set color parameter in order to have readable ouput separation
#RED is use for the word not to indicate a DOI url did not generated a Bibtex entry
RED=$( tput setaf 196 )
RESET=$( tput sgr0 )

#check if user supplied arguments or and whether stdIn is not given
#and if file is not present in the directory
if [ $# -eq 1 ] && [ -t 0 ]; then 
		
	#ask for doi	
	read -p "supply doi url: " doi 

	#Basic command to retreive bibtext like style output
	#based on doi, added the -s
	bibtex=$( curl -s -LH "Accept: text/bibliography; style=bibtex" $doi )

	#check whether the variable starts with a blank and @
	#curl returns BibTex entries with a leading blank
	#if it does not, it is most likely not a BibTex entry
	if [[ $bibtex == ?@* ]]; then
		
		#Check whether supplied file arguments already exists
		if [ ! -f $1 ]; then			
			echo "$bibtex" >> $1 
			echo "$doi has been added to new BibTex database named $1"
		else
			echo "$bibtex" >> $1
			echo "$doi has been added to $1"
		fi
	else
		printf "$doi did $RED%snot$RESET generate a BibTex entry\n"
		exit 
	fi

#check for a stuffed pipe
#if the pipe is stuffed process the doi's
elif [ $# -eq 1 ] && [ ! -t 0 ]; then 
	
	#set a counter, if curl does not result in a valid key 
	#you know on which line it happend
	counter=1

	#check database already exists so the output semantics are correct
	if [ -f $1 ]; then
		databaseStatus=", an existing database"
	else
		databaseStatus=", a newly created database"
	fi
	
	#read the input from stdIn for each line of the file do		
	while read doi; do   
		#check whether the line from stdIn is empty
		#an empty line results in an error in curl
		#so if a line is empty, substiute that line with the text empty_line
		if [ -z "$doi" ]; then
			doi="empty_line"
		fi
		
		bibtex=$( curl -k -s -LH "Accept: text/bibliography; style=bibtex" $doi )
		
		if [[ $bibtex == ?@* ]]; then
			echo "$bibtex" >> $1 
			echo "$doi has been added to $1$databaseStatus"
		else
			printf "$doi on line $counter did $RED%snot$RESET generate a BibTex entry\n"
		fi
		
		counter=$(($counter + 1))		
	done
	
else
	echo "Supply a new or already existing database as argument"
fi








