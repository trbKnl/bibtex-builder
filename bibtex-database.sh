#!/bin/bash
###################################################################
# BibTex-database generator
###################################################################
###################################################################
# Function and parameters needed for the main script
#function to create neat BibTex output
function tidyUp {
	printf "$( echo "$1" | sed 's/}, /},\\n/g' | sed 's/}}/}}\\n/g' | sed 's/ @/@/g' | sed 's/\={/ \= {/g' | sed 's/}}/}}\\n/g' )"
}

#function to extract citation key from bibtex entry
function extractCitationKey {
	echo "$1" | grep -oP '@\w+\{\K[^,]+'
}

#function to normalize DOI input (handles both plain DOIs and full URLs)
function normalizeDOI {
	local input="$1"
	# If input starts with https://doi.org/, extract just the DOI part
	if [[ $input == https://doi.org/* ]]; then
		echo "${input#https://doi.org/}"
	else
		echo "$input"
	fi
}

#set color parameter in order to have readable ouput separation
#RED is use for the word not to indicate a DOI url did not generated a Bibtex entry
RED=$( tput setaf 196 )
GREEN=$( tput setaf 46 )
RESET=$( tput sgr0 )
###################################################################
# Main script
#check if user supplied arguments or and whether stdIn is not given
#and if file is not present in the directory
if [ $# -eq 1 ] && [ -t 0 ]; then 
		
	#ask for doi	
	read -p "supply doi url: " doi_input
	#normalize the DOI (extract from URL if needed)
	doi=$( normalizeDOI "$doi_input" )
	#Basic command to retreive bibtext like style output
	#based on doi, added the -s
	bibtex=$( curl -s -LH "Accept: text/bibliography; style=bibtex" https://doi.org/$doi )
	#check whether the variable starts with a blank and @
	#curl returns BibTex entries with a leading blank
	#if it does not, it is most likely not a BibTex entry
	if [[ $bibtex == ?@* ]]; then
		
		#Check whether supplied file arguments already exists
		if [ ! -f $1 ]; then
			tidyUp "$bibtex" >> $1
			citationKey=$( extractCitationKey "$bibtex" )
			echo "$doi_input has been added to new BibTex database named $1"
			printf "Citation key: $GREEN%s$RESET\n" "$citationKey"
		else
			
			#check whether the doi is already in the database
			isAlreadyPresent=$( cat "$1" | grep "$doi" | wc -l )
			if [ $isAlreadyPresent -gt 1 ]; then
				printf "$doi_input is $RED%salready$RESET in the database\n" ; exit ; 
			fi
			tidyUp "$bibtex" >> $1
			citationKey=$( extractCitationKey "$bibtex" )
			echo "$doi_input has been added to $1"
			printf "Citation key: $GREEN%s$RESET\n" "$citationKey"
		fi
	else
		printf "$doi_input did $RED%snot$RESET generate a BibTex entry\n"
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
	while read doi_input; do   
		#check whether the line from stdIn is empty
		#an empty line results in an error in curl
		#so if a line is empty, substiute that line with the text empty_line
		if [ -z "$doi_input" ]; then
			doi_input="empty_line"
		fi
		
		#normalize the DOI (extract from URL if needed)
		doi=$( normalizeDOI "$doi_input" )
		
		bibtex=$( curl -k -s -LH "Accept: text/bibliography; style=bibtex" https://doi.org/$doi )
		
		#check whether doi is already in the database			
		isAlreadyPresent=$( cat "$1" | grep "$doi" | wc -l )
		if [[ $bibtex == ?@* ]] && [ $isAlreadyPresent -eq 1 ]; then
			tidyUp "$bibtex" >> $1
			citationKey=$( extractCitationKey "$bibtex" )
			echo "$doi_input has been added to $1$databaseStatus"
			printf "Citation key: $GREEN%s$RESET\n" "$citationKey"
		elif [[ $bibtex == ?@* ]] && [ $isAlreadyPresent -gt 1 ]; then
			printf "$doi_input is $RED%salready$RESET in the database\n" 
		else
			printf "$doi_input on line $counter did $RED%snot$RESET generate a BibTex entry\n"
		fi
		
		counter=$(($counter + 1))		
	done
	
else
	echo "Supply a new or already existing database as argument"
fi
