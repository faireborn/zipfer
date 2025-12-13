set terminal pngcairo size 800,600
set output "./results/r2_plot.png"

set datafile separator "\t"
set datafile columnheaders

set title "R^2 Score vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "R^2 Score"

set grid
set key right top
set key spacing 1.2
set rmargin 6

set style line 1 lw 2 pt 7
set style line 2 lw 2 pt 5
set style line 3 lw 2 pt 9
set style line 4 lw 2 pt 11

files  = "bpe unigram char word"
labels = "BPE ULM Char Word"

plot for [i=1:4] \
  sprintf("./results/%s.tsv", word(files,i)) \
  using "vocab_size":"R^2" with linespoints ls i title word(labels,i)
