#!/bin/bash

#ask for doi
read -p "supply doi url: " doi 

#Basic command to retreive bibtext like style output
#based on doi

echo $doi

#curl -LH "Accept: text/bibliography; style=bibtex" http://dx.doi.org/10.1038/nrd842


