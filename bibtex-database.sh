#!/bin/bash

###################################################################
# BibTex-database generator
###################################################################


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
			echo "$bibtex" >> ./$1 
			echo "A BibTex database named $1 has been created"
		else
			echo "$bibtex" >> ./$1
			echo "Entry has been added to $1 database"
		fi
	else
		echo "Url did not generate a BibTex entry"
		exit 
	fi
else
	echo "Name a new or already existing database"
fi



