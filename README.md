prepare-latex-hal-arxiv.sh
==========================

Creates a zip file containing all sources of a LaTeX document to be submitted to Arxiv / Hal.

Usage:  
    `./prepare-latex-hal-arxiv.sh [ -p infile.tex ]` *(pre-process only)*  
    `./prepare-latex-hal-arxiv.sh [ -i infile.tex ] [ -o outdir ] [ -c preview<0|1> ]`
    `./prepare-latex-hal-arxiv.sh infile.tex` 

Commands shall be run from the directory containing the input LaTeX file.

Please note that the `outdir` option to `-o` cannot be your source file's parent directory (current approach would wipe out your LaTeX source file and you don't want that, do you?)
