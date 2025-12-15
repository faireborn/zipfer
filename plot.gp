set terminal pngcairo size 800,600

set datafile separator "\t"
set datafile columnheaders

set grid
set key spacing 1.2
set rmargin 6

set style line 1 lw 2 pt 7
set style line 2 lw 2 pt 5
set style line 3 lw 2 pt 9
set style line 4 lw 2 pt 11

files  = "bpe unigram word char"
labels = "BPE ULM Word Char"

set output results_dir."/r2.png"

set key right bottom

set title "R^2 Score vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "R^2 Score"

plot for [i=1:4] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"R^2" with linespoints ls i title word(labels,i)

set output

set output results_dir."/mae.png"

set key right top

set title "MAE vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "MAE"

plot for [i=1:4] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"MAE" with linespoints ls i title word(labels,i)

set output

set output results_dir."/tokens_per_sent.png"

set key right top

set title "#tokens/sent vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#tokens/sent"

plot for [i=1:3] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"#tokens/sent" with linespoints ls i title word(labels,i)

set output

set output results_dir."/chars_per_token.png"

set key right bottom

set title "#chars/token vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#chars/token"

plot for [i=1:3] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"#chars/token" with linespoints ls i title word(labels,i)

set output

algorithms = "unigram bpe"
vocab_sizes = "2000 4000 8000 10000 20000 30000 40000 50000 60000 70000 80000 90000 100000"

do for [a in algorithms] {
    do for [v in vocab_sizes] {

        infile  = sprintf(results_dir."/%s_%s/tokens.tsv", a, v)
        outfile = sprintf(results_dir."/zipf_%s_%s.png", a, v)
 
        set output outfile
 
        set key right top
 
        set title sprintf("Zipf Plot (algorithm = %s, vocab size = %s)", a, v)
        set xlabel "log(rank)"
        set ylabel "log(freq)"

        plot infile using "log_rank":"log_freq" \
             with points pt 7 ps 0.4 title sprintf("vocab=%s", v)

        set output
    }
}
