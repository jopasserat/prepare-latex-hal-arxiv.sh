#!/bin/bash
# Creates a zip file containing all sources of a LaTeX document to be submitted to Arxiv.
# All included files are unfolded statically in a single TeX file
# The comments of the source file are removed (except the ones with \begin{comment} and the like)
#
# This is quick and dirty, but it works and I use it very often
#
# I'm looking for a re-implementation in pure python
#
# Author: Martin Monperrus
# Version of October 2014
# Public domain

OUTPUTDIR=`dirname $(tempfile)`

function usage() {
  cat << EOF
  Creates a zip file containing all sources of a LaTeX document to be submitted to Arxiv
  Usage:
  $0 file.tex 
EOF
  exit
}  # end function usage

# copying all dependencies
# new version of August 18 2013, idea taken from autopdftex.sh
function copy-resource() {
  echo copying $1
  FIGDIR=`dirname $1`
  echo creating $DIR/$FIGDIR
  mkdir -p $DIR/$FIGDIR
  cp -a $1 $DIR/$1
} # end function copy-resource


function preprocess-latex {
  # remove the comments (take care of the escaped percent
  # stop sed if \endinput is encountered
  # we end at end{input} and we comment the line (the q command quits after the line)
  # August 29  added the handling of \end{document}
  cat $1 | sed -r -e '/^[[:space:]]*%/ d' -e 's/([^\\])%.*$/\1/'  -e '$a\\n' \
    -e 's/\\endinput/%endinput/' -e '/%endinput/ q' \
    -e '/\\end\{document}/ q' | \

    # -r disable interpretation of backslash escapes which "can" be found in Latex documents ;-)
  while read -r
  do
    if [[ $REPLY =~ input || $REPLY =~ include ]]
    then
      file=`echo $REPLY | perl -ne 'if(/^[^%]*(?:input|include)\{(.*?)\}/) {print $1};'`

      # tex allows filenames without .tex
      if [[ ! -f $file ]];
      then
        file=$file.tex
      fi

      # now the recursion
      if [[ -f $file ]];
      then
        echo "% $REPLY"
        preprocess-latex $file
      else   
        echo "$REPLY"
      fi


    else
      echo "$REPLY"
    fi

  done
}

function prepare-zip() {

  TEXFILE=$1

  # first we compile to regenerate the bbl and all stuff
  latexmk -pdf TEXFILE

  DOC=${TEXFILE:0:${#TEXFILE}-4}
  PDF=$DOC.pdf

  DIR=$OUTPUTDIR/${DOC}_d

  # now cleaning the directory before zip
  #rubber --clean $DOC # we now use latexmk
  latexmk -C $DOC


  ZIPFILE=$OUTPUTDIR/$DOC-v`date +%Y%m%d`.zip

  echo output to $DIR
  mkdir -p $DIR
  #exit

  echo cleaning ...
  rm $ZIPFILE 2>/dev/null
  rm -rf $DIR/*

  # for Arxiv we need the bbl
  cp $DOC.bbl $DIR

  PP=$OUTPUTDIR/$DOC.tex
  echo copying tex files ...
  preprocess-latex $TEXFILE > $PP

  # removing comments, see http://www.monperrus.net/martin/kb
  sed -i -r -e '/^[[:space:]]*%/ d' -e 's/([^\\])%.*$/\1/' $PP

  cp $PP $DIR


  #disable path expansion in case we have {*} in the tex file
  set -f

  export IFS=$'\n'

  for i in `perl -ne 'while(/\{([^\{]*?)\}/g) {print $1,"\n"};' $PP`;
  do
    FILEROOT=
    if ((${#i}>4))
    then
      FILEROOT=${i:0:${#i}-4}
    fi

    EXT=${i:${#i}-4}
    if [[ ! $EXT == '.tex' ]];
    then
      # .tex files are not included since we preprocess before
      echo '##' $i  
      for ext in .bib .bst .sty .cls .png .jpg .pdf .dia .odg .csv ''; do
        #echo "$i$ext"
        if [ -f "$i$ext" ]
        then
          copy-resource "$i$ext"
        fi
        if [ -f "$FILEROOT$ext" ]
        then
          copy-resource "$FILEROOT$ext"
        fi
      done
    else
      echo oops this is a tex file $i
    fi
  done

  echo now entenring target directory
  cd $DIR
  for i in *dia; do dia -t eps $i; done
  #for i in *{png,jpg}; do convert $i $i.eps; done


  pushd $DIR 
  echo zipping ...

  zip -r $ZIPFILE .
  popd


  echo compiling
  pdflatex $DOC
  bibtex $DOC
  if [[ $? != 0 ]];
  then
    echo not able to bibtex
    exit
  fi

  pdflatex $DOC
  pdflatex $DOC

  OUTPUT=$DIR/$DOC-v`date +%Y%m%d`.pdf
  cp $DOC.pdf $OUTPUT

  xdg-open $OUTPUT > /dev/null 2>&1&

  unzip -l $ZIPFILE
  echo $ZIPFILE
} # end function prepare-zip

# no parameter given
if [ -z $1 ];
then 
  usage  
fi

while getopts p opt
do
  case "$opt" in
    # "-p" means only preprocessing
    p) preprocess-latex $2; exit;;
    \?) usage;;
  esac
done

prepare-zip $1
