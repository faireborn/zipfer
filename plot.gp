set terminal pngcairo size 800,600
set output "./results/r2_plot.png"

set datafile separator "\t"

set title "R^2 Score vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "R^2 Score"

set grid
set rmargin 5

plot "./results/bpe.tsv" using 1:2 with linespoints lw 2 pt 7 title "BPE", "./results/unigram.tsv" using 1:2 with linespoints lw 2 pt 7 title "ULM", "./results/char.tsv" using 1:2 with linespoints lw 2 pt 7 title "char", "./results/word.tsv" using 1:2 with linespoints lw 2 pt 7 title "word"
