#!/bin/bash

#
# docbook generator - 2009 by Christian Doebler <christian.doebler@netways.de>
#

# config
docbookXsl="/usr/share/xml/docbook/stylesheet/nwalsh/fo/docbook.xsl"
inputFile="./lconf_docbook_en"
outputFile="./lconf"

# determine binaries
xsltprocBin=`which xsltproc`
fopBin=`which fop`
db2HtmlBin=`which docbook2html`

# perform pre checks
errors=0
[[ -z $xsltprocBin ]] && echo "ERROR: xsltproc not found!" && errors=1
[[ -z $fopBin ]] && echo "ERROR: fop not found!" && errors=1
[[ -z $db2HtmlBin ]] && echo "ERROR: docbook2html not found!" && errors=1
[[ ! -e $inputFile.xml ]] && echo "ERROR: $inputFile.xml!" && errors=1
[[ ! -e $docbookXsl ]] && echo "ERROR: $docbookXsl not found!" && errors=1
[[ $errors -ne 0 ]] && echo "One or more errors occurred! EXITING!" && exit 1

# create docbook
$xsltprocBin -o $outputFile.fo --stringparam use.extensions 0 --stringparam fop1.extensions 1 $docbookXsl $inputFile.xml
$fopBin -fo $outputFile.fo -pdf $outputFile.pdf
$db2HtmlBin --nochunks $inputFile.xml

# fix html
#cat $inputFile.html | tr '\n' ' ' | sed 's/\(<img[^>]\+>\)/<div style="clear:both;">\1<\/div>/gi' > $outputFile.html
cat $inputFile.html | tr '\n' ' ' | sed 's/\(<img[^>]\+>\)//gi' > $outputFile.html
rm $inputFile.html

# clean up
rm $outputFile.fo
