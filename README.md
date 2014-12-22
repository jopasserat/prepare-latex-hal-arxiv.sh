prepare-latex-hal-arxiv.sh
==========================

Creates a zip file containing all sources of a LaTeX document to be submitted to Arxiv / Hal.

Usage:  
    `./prepare-latex-hal-arxiv.sh [ -p infile.tex ]` *(pre-process only)*  
    `/home/jopasserat/papers/tools/zip2hal.sh [ -i infile.tex ] [ -o outdir ] [ -c preview<0|1> ]`
    `./prepare-latex-hal-arxiv.sh infile.tex` 

Warning: `outdir` cannot be your current directory (current approach would wipe out your LaTeX source file and you don't want that, do you?)
