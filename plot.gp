set terminal pngcairo size 800,600

set datafile separator "\t"
set datafile columnheaders

set grid
set key right top
set key spacing 1.2
set rmargin 6

set style line 1 lw 2 pt 7
set style line 2 lw 2 pt 5
set style line 3 lw 2 pt 9
set style line 4 lw 2 pt 11

files  = "bpe unigram word char"
labels = "BPE ULM Word Char"

set output "./results/r2.png"

set title "R^2 Score vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "R^2 Score"

plot for [i=1:4] \
  sprintf("./results/%s.tsv", word(files,i)) \
  using "vocab_size":"R^2" with linespoints ls i title word(labels,i)

set output

set output "./results/mae.png"

set title "MAE vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "MAE"

plot for [i=1:4] \
  sprintf("./results/%s.tsv", word(files,i)) \
  using "vocab_size":"MAE" with linespoints ls i title word(labels,i)

set output

set output "./results/tokens_per_sent.png"

set title "#tokens/sent vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#tokens/sent"

plot for [i=1:3] \
  sprintf("./results/%s.tsv", word(files,i)) \
  using "vocab_size":"#tokens/sent" with linespoints ls i title word(labels,i)

set output

set output "./results/chars_per_token.png"

set key right bottom

set title "#chars/token vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#chars/token"

plot for [i=1:3] \
  sprintf("./results/%s.tsv", word(files,i)) \
  using "vocab_size":"#chars/token" with linespoints ls i title word(labels,i)

set output
