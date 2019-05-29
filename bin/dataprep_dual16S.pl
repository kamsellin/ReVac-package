#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use warnings;
use Data::Dumper;

#******************************************************************************
# *dataprep_dual16S.pl
# Author: james robert white, james.dna.white@gmail.com

# This function takes the input parameters for the 16S pipeline and 
# determines how to preprocess the data for the pipeline.

# If a single fasta is provided we assume it's a barcoded sample. Don't 
# change anything to it or the mapping file. 

# If multiple fasta files are given we assume the sequences are trimmed and 
# each individual fasta file is a different sample. Samples are described
# by the associated meta file. These must be processed for the pipeline.
# 
# The outputs of this program are *.processed.fna and *.processed.map
#******************************************************************************
use Getopt::Std;
use File::Copy;

use vars qw/$opt_f $opt_q $opt_m $opt_p/;

getopts("f:m:q:p:");

my $usage = "Usage:  $0 \
                -f list of fasta input files\
                -q list of qual score files\
                -m input mapping file\
                -p output prefix for the processed files\
                \n";

die $usage unless defined $opt_f
              and defined $opt_m
              and defined $opt_p;

my $list     = $opt_f;
my $quallist = $opt_q;
my $mapfile  = $opt_m;
my $prefix   = $opt_p;


my $finalseqfile  = "$prefix.processed.fasta"; 
my $finalqualfile = "$prefix.processed.qual";
my $finalmapfile  = "$prefix.processed.map";

my %data = ();
my $ARTIFICIAL_PRIMER  = "CATGCTGCCTCCCGTAGGAGT";
my $ARTIFICIAL_QUALSTR = "40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40";
my @barcodes = qw/AAAAAAAA AAAAAAAC AAAAAAAG AAAAAAAT AAAAAACA AAAAAACC AAAAAACG AAAAAACT 
AAAAAAGA AAAAAAGC AAAAAAGG AAAAAAGT AAAAAATA AAAAAATC AAAAAATG AAAAAATT 
AAAAACAA AAAAACAC AAAAACAG AAAAACAT AAAAACCA AAAAACCC AAAAACCG AAAAACCT 
AAAAACGA AAAAACGC AAAAACGG AAAAACGT AAAAACTA AAAAACTC AAAAACTG AAAAACTT 
AAAAAGAA AAAAAGAC AAAAAGAG AAAAAGAT AAAAAGCA AAAAAGCC AAAAAGCG AAAAAGCT 
AAAAAGGA AAAAAGGC AAAAAGGG AAAAAGGT AAAAAGTA AAAAAGTC AAAAAGTG AAAAAGTT 
AAAAATAA AAAAATAC AAAAATAG AAAAATAT AAAAATCA AAAAATCC AAAAATCG AAAAATCT 
AAAAATGA AAAAATGC AAAAATGG AAAAATGT AAAAATTA AAAAATTC AAAAATTG AAAAATTT 
AAAACAAA AAAACAAC AAAACAAG AAAACAAT AAAACACA AAAACACC AAAACACG AAAACACT 
AAAACAGA AAAACAGC AAAACAGG AAAACAGT AAAACATA AAAACATC AAAACATG AAAACATT 
AAAACCAA AAAACCAC AAAACCAG AAAACCAT AAAACCCA AAAACCCC AAAACCCG AAAACCCT 
AAAACCGA AAAACCGC AAAACCGG AAAACCGT AAAACCTA AAAACCTC AAAACCTG AAAACCTT 
AAAACGAA AAAACGAC AAAACGAG AAAACGAT AAAACGCA AAAACGCC AAAACGCG AAAACGCT 
AAAACGGA AAAACGGC AAAACGGG AAAACGGT AAAACGTA AAAACGTC AAAACGTG AAAACGTT 
AAAACTAA AAAACTAC AAAACTAG AAAACTAT AAAACTCA AAAACTCC AAAACTCG AAAACTCT 
AAAACTGA AAAACTGC AAAACTGG AAAACTGT AAAACTTA AAAACTTC AAAACTTG AAAACTTT 
AAAAGAAA AAAAGAAC AAAAGAAG AAAAGAAT AAAAGACA AAAAGACC AAAAGACG AAAAGACT 
AAAAGAGA AAAAGAGC AAAAGAGG AAAAGAGT AAAAGATA AAAAGATC AAAAGATG AAAAGATT 
AAAAGCAA AAAAGCAC AAAAGCAG AAAAGCAT AAAAGCCA AAAAGCCC AAAAGCCG AAAAGCCT 
AAAAGCGA AAAAGCGC AAAAGCGG AAAAGCGT AAAAGCTA AAAAGCTC AAAAGCTG AAAAGCTT 
AAAAGGAA AAAAGGAC AAAAGGAG AAAAGGAT AAAAGGCA AAAAGGCC AAAAGGCG AAAAGGCT 
AAAAGGGA AAAAGGGC AAAAGGGG AAAAGGGT AAAAGGTA AAAAGGTC AAAAGGTG AAAAGGTT 
AAAAGTAA AAAAGTAC AAAAGTAG AAAAGTAT AAAAGTCA AAAAGTCC AAAAGTCG AAAAGTCT 
AAAAGTGA AAAAGTGC AAAAGTGG AAAAGTGT AAAAGTTA AAAAGTTC AAAAGTTG AAAAGTTT 
AAAATAAA AAAATAAC AAAATAAG AAAATAAT AAAATACA AAAATACC AAAATACG AAAATACT 
AAAATAGA AAAATAGC AAAATAGG AAAATAGT AAAATATA AAAATATC AAAATATG AAAATATT 
AAAATCAA AAAATCAC AAAATCAG AAAATCAT AAAATCCA AAAATCCC AAAATCCG AAAATCCT 
AAAATCGA AAAATCGC AAAATCGG AAAATCGT AAAATCTA AAAATCTC AAAATCTG AAAATCTT 
AAAATGAA AAAATGAC AAAATGAG AAAATGAT AAAATGCA AAAATGCC AAAATGCG AAAATGCT 
AAAATGGA AAAATGGC AAAATGGG AAAATGGT AAAATGTA AAAATGTC AAAATGTG AAAATGTT 
AAAATTAA AAAATTAC AAAATTAG AAAATTAT AAAATTCA AAAATTCC AAAATTCG AAAATTCT 
AAAATTGA AAAATTGC AAAATTGG AAAATTGT AAAATTTA AAAATTTC AAAATTTG AAAATTTT 
AAACAAAA AAACAAAC AAACAAAG AAACAAAT AAACAACA AAACAACC AAACAACG AAACAACT 
AAACAAGA AAACAAGC AAACAAGG AAACAAGT AAACAATA AAACAATC AAACAATG AAACAATT 
AAACACAA AAACACAC AAACACAG AAACACAT AAACACCA AAACACCC AAACACCG AAACACCT 
AAACACGA AAACACGC AAACACGG AAACACGT AAACACTA AAACACTC AAACACTG AAACACTT 
AAAGACAA AAAGACAC AAAGACAG AAAGACAT AAAGACCA AAAGACCC AAAGACCG AAAGACCT 
AAAGACGA AAAGACGC AAAGACGG AAAGACGT AAAGACTA AAAGACTC AAAGACTG AAAGACTT 
AAAGAGAA AAAGAGAC AAAGAGAG AAAGAGAT AAAGAGCA AAAGAGCC AAAGAGCG AAAGAGCT 
AAAGAGGA AAAGAGGC AAAGAGGG AAAGAGGT AAAGAGTA AAAGAGTC AAAGAGTG AAAGAGTT 
AAAGATAA AAAGATAC AAAGATAG AAAGATAT AAAGATCA AAAGATCC AAAGATCG AAAGATCT 
AAAGATGA AAAGATGC AAAGATGG AAAGATGT AAAGATTA AAAGATTC AAAGATTG AAAGATTT 
AAAGCAAA AAAGCAAC AAAGCAAG AAAGCAAT AAAGCACA AAAGCACC AAAGCACG AAAGCACT 
AAAGCAGA AAAGCAGC AAAGCAGG AAAGCAGT AAAGCATA AAAGCATC AAAGCATG AAAGCATT 
AAAGCCAA AAAGCCAC AAAGCCAG AAAGCCAT AAAGCCCA AAAGCCCC AAAGCCCG AAAGCCCT 
AAAGCCGA AAAGCCGC AAAGCCGG AAAGCCGT AAAGCCTA AAAGCCTC AAAGCCTG AAAGCCTT 
AAAGCGAA AAAGCGAC AAAGCGAG AAAGCGAT AAAGCGCA AAAGCGCC AAAGCGCG AAAGCGCT 
AAAGCGGA AAAGCGGC AAAGCGGG AAAGCGGT AAAGCGTA AAAGCGTC AAAGCGTG AAAGCGTT 
AAAGCTAA AAAGCTAC AAAGCTAG AAAGCTAT AAAGCTCA AAAGCTCC AAAGCTCG AAAGCTCT 
AAAGCTGA AAAGCTGC AAAGCTGG AAAGCTGT AAAGCTTA AAAGCTTC AAAGCTTG AAAGCTTT 
AAAGGAAA AAAGGAAC AAAGGAAG AAAGGAAT AAAGGACA AAAGGACC AAAGGACG AAAGGACT 
AAAGGAGA AAAGGAGC AAAGGAGG AAAGGAGT AAAGGATA AAAGGATC AAAGGATG AAAGGATT 
AAAGGCAA AAAGGCAC AAAGGCAG AAAGGCAT AAAGGCCA AAAGGCCC AAAGGCCG AAAGGCCT 
AAAGGCGA AAAGGCGC AAAGGCGG AAAGGCGT AAAGGCTA AAAGGCTC AAAGGCTG AAAGGCTT 
AAAGGGAA AAAGGGAC AAAGGGAG AAAGGGAT AAAGGGCA AAAGGGCC AAAGGGCG AAAGGGCT 
AAAGGGGA AAAGGGGC AAAGGGGG AAAGGGGT AAAGGGTA AAAGGGTC AAAGGGTG AAAGGGTT 
AAAGGTAA AAAGGTAC AAAGGTAG AAAGGTAT AAAGGTCA AAAGGTCC AAAGGTCG AAAGGTCT 
AAAGGTGA AAAGGTGC AAAGGTGG AAAGGTGT AAAGGTTA AAAGGTTC AAAGGTTG AAAGGTTT 
AAAGTAAA AAAGTAAC AAAGTAAG AAAGTAAT AAAGTACA AAAGTACC AAAGTACG AAAGTACT 
AAAGTAGA AAAGTAGC AAAGTAGG AAAGTAGT AAAGTATA AAAGTATC AAAGTATG AAAGTATT 
AAAGTCAA AAAGTCAC AAAGTCAG AAAGTCAT AAAGTCCA AAAGTCCC AAAGTCCG AAAGTCCT 
AAAGTCGA AAAGTCGC AAAGTCGG AAAGTCGT AAAGTCTA AAAGTCTC AAAGTCTG AAAGTCTT 
AAAGTGAA AAAGTGAC AAAGTGAG AAAGTGAT AAAGTGCA AAAGTGCC AAAGTGCG AAAGTGCT 
AAAGTGGA AAAGTGGC AAAGTGGG AAAGTGGT AAAGTGTA AAAGTGTC AAAGTGTG AAAGTGTT 
AAAGTTAA AAAGTTAC AAAGTTAG AAAGTTAT AAAGTTCA AAAGTTCC AAAGTTCG AAAGTTCT 
AAAGTTGA AAAGTTGC AAAGTTGG AAAGTTGT AAAGTTTA AAAGTTTC AAAGTTTG AAAGTTTT 
AAATAAAA AAATAAAC AAATAAAG AAATAAAT AAATAACA AAATAACC AAATAACG AAATAACT 
AAATAAGA AAATAAGC AAATAAGG AAATAAGT AAATAATA AAATAATC AAATAATG AAATAATT 
AAATACAA AAATACAC AAATACAG AAATACAT AAATACCA AAATACCC AAATACCG AAATACCT 
AAATACGA AAATACGC AAATACGG AAATACGT AAATACTA AAATACTC AAATACTG AAATACTT 
AAATAGAA AAATAGAC AAATAGAG AAATAGAT AAATAGCA AAATAGCC AAATAGCG AAATAGCT 
AAATAGGA AAATAGGC AAATAGGG AAATAGGT AAATAGTA AAATAGTC AAATAGTG AAATAGTT 
CATAACGA CATAACGC CATAACGG CATAACGT CATAACTA CATAACTC CATAACTG CATAACTT 
CATAAGAA CATAAGAC CATAAGAG CATAAGAT CATAAGCA CATAAGCC CATAAGCG CATAAGCT 
CATAAGGA CATAAGGC CATAAGGG CATAAGGT CATAAGTA CATAAGTC CATAAGTG CATAAGTT 
CATAATAA CATAATAC CATAATAG CATAATAT CATAATCA CATAATCC CATAATCG CATAATCT 
CATAATGA CATAATGC CATAATGG CATAATGT CATAATTA CATAATTC CATAATTG CATAATTT 
CATACAAA CATACAAC CATACAAG CATACAAT CATACACA CATACACC CATACACG CATACACT 
CATACAGA CATACAGC CATACAGG CATACAGT CATACATA CATACATC CATACATG CATACATT 
CATACCAA CATACCAC CATACCAG CATACCAT CATACCCA CATACCCC CATACCCG CATACCCT 
CATACCGA CATACCGC CATACCGG CATACCGT CATACCTA CATACCTC CATACCTG CATACCTT 
CATACGAA CATACGAC CATACGAG CATACGAT CATACGCA CATACGCC CATACGCG CATACGCT 
CATACGGA CATACGGC CATACGGG CATACGGT CATACGTA CATACGTC CATACGTG CATACGTT 
CATACTAA CATACTAC CATACTAG CATACTAT CATACTCA CATACTCC CATACTCG CATACTCT 
CATACTGA CATACTGC CATACTGG CATACTGT CATACTTA CATACTTC CATACTTG CATACTTT 
CATAGAAA CATAGAAC CATAGAAG CATAGAAT CATAGACA CATAGACC CATAGACG CATAGACT 
CATAGAGA CATAGAGC CATAGAGG CATAGAGT CATAGATA CATAGATC CATAGATG CATAGATT 
CATAGCAA CATAGCAC CATAGCAG CATAGCAT CATAGCCA CATAGCCC CATAGCCG CATAGCCT 
CATAGCGA CATAGCGC CATAGCGG CATAGCGT CATAGCTA CATAGCTC CATAGCTG CATAGCTT 
CATAGGAA CATAGGAC CATAGGAG CATAGGAT CATAGGCA CATAGGCC CATAGGCG CATAGGCT 
CATAGGGA CATAGGGC CATAGGGG CATAGGGT CATAGGTA CATAGGTC CATAGGTG CATAGGTT 
CATAGTAA CATAGTAC CATAGTAG CATAGTAT CATAGTCA CATAGTCC CATAGTCG CATAGTCT 
CATAGTGA CATAGTGC CATAGTGG CATAGTGT CATAGTTA CATAGTTC CATAGTTG CATAGTTT 
CATATAAA CATATAAC CATATAAG CATATAAT CATATACA CATATACC CATATACG CATATACT 
CATATAGA CATATAGC CATATAGG CATATAGT CATATATA CATATATC CATATATG CATATATT 
CATATCAA CATATCAC CATATCAG CATATCAT CATATCCA CATATCCC CATATCCG CATATCCT 
CATATCGA CATATCGC CATATCGG CATATCGT CATATCTA CATATCTC CATATCTG CATATCTT 
CATATGAA CATATGAC CATATGAG CATATGAT CATATGCA CATATGCC CATATGCG CATATGCT 
CATATGGA CATATGGC CATATGGG CATATGGT CATATGTA CATATGTC CATATGTG CATATGTT 
CATATTAA CATATTAC CATATTAG CATATTAT CATATTCA CATATTCC CATATTCG CATATTCT 
CATATTGA CATATTGC CATATTGG CATATTGT CATATTTA CATATTTC CATATTTG CATATTTT 
CATCAAAA CATCAAAC CATCAAAG CATCAAAT CATCAACA CATCAACC CATCAACG CATCAACT 
CATCAAGA CATCAAGC CATCAAGG CATCAAGT CATCAATA CATCAATC CATCAATG CATCAATT 
CATCACAA CATCACAC CATCACAG CATCACAT CATCACCA CATCACCC CATCACCG CATCACCT 
CATCACGA CATCACGC CATCACGG CATCACGT CATCACTA CATCACTC CATCACTG CATCACTT 
CATCAGAA CATCAGAC CATCAGAG CATCAGAT CATCAGCA CATCAGCC CATCAGCG CATCAGCT 
CATCAGGA CATCAGGC CATCAGGG CATCAGGT CATCAGTA CATCAGTC CATCAGTG CATCAGTT 
CATCATAA CATCATAC CATCATAG CATCATAT CATCATCA CATCATCC CATCATCG CATCATCT 
CCGTTCGA CCGTTCGC CCGTTCGG CCGTTCGT CCGTTCTA CCGTTCTC CCGTTCTG CCGTTCTT 
CCGTTGAA CCGTTGAC CCGTTGAG CCGTTGAT CCGTTGCA CCGTTGCC CCGTTGCG CCGTTGCT 
CCGTTGGA CCGTTGGC CCGTTGGG CCGTTGGT CCGTTGTA CCGTTGTC CCGTTGTG CCGTTGTT 
CCGTTTAA CCGTTTAC CCGTTTAG CCGTTTAT CCGTTTCA CCGTTTCC CCGTTTCG CCGTTTCT 
CCGTTTGA CCGTTTGC CCGTTTGG CCGTTTGT CCGTTTTA CCGTTTTC CCGTTTTG CCGTTTTT 
CCTAAAAA CCTAAAAC CCTAAAAG CCTAAAAT CCTAAACA CCTAAACC CCTAAACG CCTAAACT 
CCTAAAGA CCTAAAGC CCTAAAGG CCTAAAGT CCTAAATA CCTAAATC CCTAAATG CCTAAATT 
CCTAACAA CCTAACAC CCTAACAG CCTAACAT CCTAACCA CCTAACCC CCTAACCG CCTAACCT 
CCTAACGA CCTAACGC CCTAACGG CCTAACGT CCTAACTA CCTAACTC CCTAACTG CCTAACTT 
CCTAAGAA CCTAAGAC CCTAAGAG CCTAAGAT CCTAAGCA CCTAAGCC CCTAAGCG CCTAAGCT 
CCTAAGGA CCTAAGGC CCTAAGGG CCTAAGGT CCTAAGTA CCTAAGTC CCTAAGTG CCTAAGTT 
CCTAATAA CCTAATAC CCTAATAG CCTAATAT CCTAATCA CCTAATCC CCTAATCG CCTAATCT 
CCTAATGA CCTAATGC CCTAATGG CCTAATGT CCTAATTA CCTAATTC CCTAATTG CCTAATTT 
CCTACAAA CCTACAAC CCTACAAG CCTACAAT CCTACACA CCTACACC CCTACACG CCTACACT 
CCTACAGA CCTACAGC CCTACAGG CCTACAGT CCTACATA CCTACATC CCTACATG CCTACATT 
CCTACCAA CCTACCAC CCTACCAG CCTACCAT CCTACCCA CCTACCCC CCTACCCG CCTACCCT 
CCTACCGA CCTACCGC CCTACCGG CCTACCGT CCTACCTA CCTACCTC CCTACCTG CCTACCTT 
CCTACGAA CCTACGAC CCTACGAG CCTACGAT CCTACGCA CCTACGCC CCTACGCG CCTACGCT 
CCTACGGA CCTACGGC CCTACGGG CCTACGGT CCTACGTA CCTACGTC CCTACGTG CCTACGTT 
CCTACTAA CCTACTAC CCTACTAG CCTACTAT CCTACTCA CCTACTCC CCTACTCG CCTACTCT 
CCTACTGA CCTACTGC CCTACTGG CCTACTGT CCTACTTA CCTACTTC CCTACTTG CCTACTTT 
CCTAGAAA CCTAGAAC CCTAGAAG CCTAGAAT CCTAGACA CCTAGACC CCTAGACG CCTAGACT 
CCTAGAGA CCTAGAGC CCTAGAGG CCTAGAGT CCTAGATA CCTAGATC CCTAGATG CCTAGATT 
CCTAGCAA CCTAGCAC CCTAGCAG CCTAGCAT CCTAGCCA CCTAGCCC CCTAGCCG CCTAGCCT 
CCTAGCGA CCTAGCGC CCTAGCGG CCTAGCGT CCTAGCTA CCTAGCTC CCTAGCTG CCTAGCTT 
CCTAGGAA CCTAGGAC CCTAGGAG CCTAGGAT CCTAGGCA CCTAGGCC CCTAGGCG CCTAGGCT 
CCTAGGGA CCTAGGGC CCTAGGGG CCTAGGGT CCTAGGTA CCTAGGTC CCTAGGTG CCTAGGTT 
CCTAGTAA CCTAGTAC CCTAGTAG CCTAGTAT CCTAGTCA CCTAGTCC CCTAGTCG CCTAGTCT 
CCTAGTGA CCTAGTGC CCTAGTGG CCTAGTGT CCTAGTTA CCTAGTTC CCTAGTTG CCTAGTTT 
CCTATAAA CCTATAAC CCTATAAG CCTATAAT CCTATACA CCTATACC CCTATACG CCTATACT 
CCTATAGA CCTATAGC CCTATAGG CCTATAGT CCTATATA CCTATATC CCTATATG CCTATATT 
CCTATCAA CCTATCAC CCTATCAG CCTATCAT CCTATCCA CCTATCCC CCTATCCG CCTATCCT 
CCTATCGA CCTATCGC CCTATCGG CCTATCGT CCTATCTA CCTATCTC CCTATCTG CCTATCTT 
CCTATGAA CCTATGAC CCTATGAG CCTATGAT CCTATGCA CCTATGCC CCTATGCG CCTATGCT 
CCTATGGA CCTATGGC CCTATGGG CCTATGGT CCTATGTA CCTATGTC CCTATGTG CCTATGTT 
CCTATTAA CCTATTAC CCTATTAG CCTATTAT CCTATTCA CCTATTCC CCTATTCG CCTATTCT 
CGGTGCGA CGGTGCGC CGGTGCGG CGGTGCGT CGGTGCTA CGGTGCTC CGGTGCTG CGGTGCTT 
CGGTGGAA CGGTGGAC CGGTGGAG CGGTGGAT CGGTGGCA CGGTGGCC CGGTGGCG CGGTGGCT 
CGGTGGGA CGGTGGGC CGGTGGGG CGGTGGGT CGGTGGTA CGGTGGTC CGGTGGTG CGGTGGTT 
CGGTGTAA CGGTGTAC CGGTGTAG CGGTGTAT CGGTGTCA CGGTGTCC CGGTGTCG CGGTGTCT 
CGGTGTGA CGGTGTGC CGGTGTGG CGGTGTGT CGGTGTTA CGGTGTTC CGGTGTTG CGGTGTTT 
CGGTTAAA CGGTTAAC CGGTTAAG CGGTTAAT CGGTTACA CGGTTACC CGGTTACG CGGTTACT 
CGGTTAGA CGGTTAGC CGGTTAGG CGGTTAGT CGGTTATA CGGTTATC CGGTTATG CGGTTATT 
CGGTTCAA CGGTTCAC CGGTTCAG CGGTTCAT CGGTTCCA CGGTTCCC CGGTTCCG CGGTTCCT 
CGGTTCGA CGGTTCGC CGGTTCGG CGGTTCGT CGGTTCTA CGGTTCTC CGGTTCTG CGGTTCTT 
CGGTTGAA CGGTTGAC CGGTTGAG CGGTTGAT CGGTTGCA CGGTTGCC CGGTTGCG CGGTTGCT 
CGGTTGGA CGGTTGGC CGGTTGGG CGGTTGGT CGGTTGTA CGGTTGTC CGGTTGTG CGGTTGTT 
CGGTTTAA CGGTTTAC CGGTTTAG CGGTTTAT CGGTTTCA CGGTTTCC CGGTTTCG CGGTTTCT 
CGGTTTGA CGGTTTGC CGGTTTGG CGGTTTGT CGGTTTTA CGGTTTTC CGGTTTTG CGGTTTTT 
CGTAAAAA CGTAAAAC CGTAAAAG CGTAAAAT CGTAAACA CGTAAACC CGTAAACG CGTAAACT 
CGTAAAGA CGTAAAGC CGTAAAGG CGTAAAGT CGTAAATA CGTAAATC CGTAAATG CGTAAATT 
CGTAACAA CGTAACAC CGTAACAG CGTAACAT CGTAACCA CGTAACCC CGTAACCG CGTAACCT 
CGTAACGA CGTAACGC CGTAACGG CGTAACGT CGTAACTA CGTAACTC CGTAACTG CGTAACTT 
CGTAAGAA CGTAAGAC CGTAAGAG CGTAAGAT CGTAAGCA CGTAAGCC CGTAAGCG CGTAAGCT 
CGTAAGGA CGTAAGGC CGTAAGGG CGTAAGGT CGTAAGTA CGTAAGTC CGTAAGTG CGTAAGTT 
CGTAATAA CGTAATAC CGTAATAG CGTAATAT CGTAATCA CGTAATCC CGTAATCG CGTAATCT 
CGTAATGA CGTAATGC CGTAATGG CGTAATGT CGTAATTA CGTAATTC CGTAATTG CGTAATTT 
CGTACAAA CGTACAAC CGTACAAG CGTACAAT CGTACACA CGTACACC CGTACACG CGTACACT 
CGTACAGA CGTACAGC CGTACAGG CGTACAGT CGTACATA CGTACATC CGTACATG CGTACATT 
CGTACCAA CGTACCAC CGTACCAG CGTACCAT CGTACCCA CGTACCCC CGTACCCG CGTACCCT 
CGTACCGA CGTACCGC CGTACCGG CGTACCGT CGTACCTA CGTACCTC CGTACCTG CGTACCTT 
CGTACGAA CGTACGAC CGTACGAG CGTACGAT CGTACGCA CGTACGCC CGTACGCG CGTACGCT 
CGTACGGA CGTACGGC CGTACGGG CGTACGGT CGTACGTA CGTACGTC CGTACGTG CGTACGTT 
CGTACTAA CGTACTAC CGTACTAG CGTACTAT CGTACTCA CGTACTCC CGTACTCG CGTACTCT 
CGTACTGA CGTACTGC CGTACTGG CGTACTGT CGTACTTA CGTACTTC CGTACTTG CGTACTTT 
CGTAGAAA CGTAGAAC CGTAGAAG CGTAGAAT CGTAGACA CGTAGACC CGTAGACG CGTAGACT 
CGTAGAGA CGTAGAGC CGTAGAGG CGTAGAGT CGTAGATA CGTAGATC CGTAGATG CGTAGATT 
CGTAGCAA CGTAGCAC CGTAGCAG CGTAGCAT CGTAGCCA CGTAGCCC CGTAGCCG CGTAGCCT 
CGTAGCGA CGTAGCGC CGTAGCGG CGTAGCGT CGTAGCTA CGTAGCTC CGTAGCTG CGTAGCTT 
CGTAGGAA CGTAGGAC CGTAGGAG CGTAGGAT CGTAGGCA CGTAGGCC CGTAGGCG CGTAGGCT 
CGTAGGGA CGTAGGGC CGTAGGGG CGTAGGGT CGTAGGTA CGTAGGTC CGTAGGTG CGTAGGTT 
CGTAGTAA CGTAGTAC CGTAGTAG CGTAGTAT CGTAGTCA CGTAGTCC CGTAGTCG CGTAGTCT
GACACCGA GACACCGC GACACCGG GACACCGT GACACCTA GACACCTC GACACCTG GACACCTT 
GACACGAA GACACGAC GACACGAG GACACGAT GACACGCA GACACGCC GACACGCG GACACGCT 
GACACGGA GACACGGC GACACGGG GACACGGT GACACGTA GACACGTC GACACGTG GACACGTT 
GACACTAA GACACTAC GACACTAG GACACTAT GACACTCA GACACTCC GACACTCG GACACTCT 
GACACTGA GACACTGC GACACTGG GACACTGT GACACTTA GACACTTC GACACTTG GACACTTT 
GACAGAAA GACAGAAC GACAGAAG GACAGAAT GACAGACA GACAGACC GACAGACG GACAGACT 
GACAGAGA GACAGAGC GACAGAGG GACAGAGT GACAGATA GACAGATC GACAGATG GACAGATT 
GACAGCAA GACAGCAC GACAGCAG GACAGCAT GACAGCCA GACAGCCC GACAGCCG GACAGCCT 
GACAGCGA GACAGCGC GACAGCGG GACAGCGT GACAGCTA GACAGCTC GACAGCTG GACAGCTT 
GACAGGAA GACAGGAC GACAGGAG GACAGGAT GACAGGCA GACAGGCC GACAGGCG GACAGGCT 
GACAGGGA GACAGGGC GACAGGGG GACAGGGT GACAGGTA GACAGGTC GACAGGTG GACAGGTT 
GACAGTAA GACAGTAC GACAGTAG GACAGTAT GACAGTCA GACAGTCC GACAGTCG GACAGTCT 
GACAGTGA GACAGTGC GACAGTGG GACAGTGT GACAGTTA GACAGTTC GACAGTTG GACAGTTT 
GACATAAA GACATAAC GACATAAG GACATAAT GACATACA GACATACC GACATACG GACATACT 
GACATAGA GACATAGC GACATAGG GACATAGT GACATATA GACATATC GACATATG GACATATT 
GACATCAA GACATCAC GACATCAG GACATCAT GACATCCA GACATCCC GACATCCG GACATCCT 
GACATCGA GACATCGC GACATCGG GACATCGT GACATCTA GACATCTC GACATCTG GACATCTT 
GACATGAA GACATGAC GACATGAG GACATGAT GACATGCA GACATGCC GACATGCG GACATGCT 
GACATGGA GACATGGC GACATGGG GACATGGT GACATGTA GACATGTC GACATGTG GACATGTT 
GACATTAA GACATTAC GACATTAG GACATTAT GACATTCA GACATTCC GACATTCG GACATTCT 
GACATTGA GACATTGC GACATTGG GACATTGT GACATTTA GACATTTC GACATTTG GACATTTT 
GACCAAAA GACCAAAC GACCAAAG GACCAAAT GACCAACA GACCAACC GACCAACG GACCAACT 
GACCAAGA GACCAAGC GACCAAGG GACCAAGT GACCAATA GACCAATC GACCAATG GACCAATT 
GACCACAA GACCACAC GACCACAG GACCACAT GACCACCA GACCACCC GACCACCG GACCACCT 
GACCACGA GACCACGC GACCACGG GACCACGT GACCACTA GACCACTC GACCACTG GACCACTT 
GACCAGAA GACCAGAC GACCAGAG GACCAGAT GACCAGCA GACCAGCC GACCAGCG GACCAGCT 
GACCAGGA GACCAGGC GACCAGGG GACCAGGT GACCAGTA GACCAGTC GACCAGTG GACCAGTT 
GACCATAA GACCATAC GACCATAG GACCATAT GACCATCA GACCATCC GACCATCG GACCATCT 
GACCATGA GACCATGC GACCATGG GACCATGT GACCATTA GACCATTC GACCATTG GACCATTT 
GACCCAAA GACCCAAC GACCCAAG GACCCAAT GACCCACA GACCCACC GACCCACG GACCCACT 
GACCCAGA GACCCAGC GACCCAGG GACCCAGT GACCCATA GACCCATC GACCCATG GACCCATT 
GACCCCAA GACCCCAC GACCCCAG GACCCCAT GACCCCCA GACCCCCC GACCCCCG GACCCCCT 
GACCCCGA GACCCCGC GACCCCGG GACCCCGT GACCCCTA GACCCCTC GACCCCTG GACCCCTT 
GACCCGAA GACCCGAC GACCCGAG GACCCGAT GACCCGCA GACCCGCC GACCCGCG GACCCGCT 
GACCCGGA GACCCGGC GACCCGGG GACCCGGT GACCCGTA GACCCGTC GACCCGTG GACCCGTT 
GACCCTAA GACCCTAC GACCCTAG GACCCTAT GACCCTCA GACCCTCC GACCCTCG GACCCTCT 
GCAGTTGA GCAGTTGC GCAGTTGG GCAGTTGT GCAGTTTA GCAGTTTC GCAGTTTG GCAGTTTT 
GCATAAAA GCATAAAC GCATAAAG GCATAAAT GCATAACA GCATAACC GCATAACG GCATAACT 
GCATAAGA GCATAAGC GCATAAGG GCATAAGT GCATAATA GCATAATC GCATAATG GCATAATT 
GCATACAA GCATACAC GCATACAG GCATACAT GCATACCA GCATACCC GCATACCG GCATACCT 
GCATACGA GCATACGC GCATACGG GCATACGT GCATACTA GCATACTC GCATACTG GCATACTT 
GCATAGAA GCATAGAC GCATAGAG GCATAGAT GCATAGCA GCATAGCC GCATAGCG GCATAGCT 
GCATAGGA GCATAGGC GCATAGGG GCATAGGT GCATAGTA GCATAGTC GCATAGTG GCATAGTT 
GCATATAA GCATATAC GCATATAG GCATATAT GCATATCA GCATATCC GCATATCG GCATATCT 
GCATATGA GCATATGC GCATATGG GCATATGT GCATATTA GCATATTC GCATATTG GCATATTT 
GCATCAAA GCATCAAC GCATCAAG GCATCAAT GCATCACA GCATCACC GCATCACG GCATCACT 
GCATCAGA GCATCAGC GCATCAGG GCATCAGT GCATCATA GCATCATC GCATCATG GCATCATT 
GCATCCAA GCATCCAC GCATCCAG GCATCCAT GCATCCCA GCATCCCC GCATCCCG GCATCCCT 
GCATCCGA GCATCCGC GCATCCGG GCATCCGT GCATCCTA GCATCCTC GCATCCTG GCATCCTT 
GCATCGAA GCATCGAC GCATCGAG GCATCGAT GCATCGCA GCATCGCC GCATCGCG GCATCGCT 
GCATCGGA GCATCGGC GCATCGGG GCATCGGT GCATCGTA GCATCGTC GCATCGTG GCATCGTT 
GCATCTAA GCATCTAC GCATCTAG GCATCTAT GCATCTCA GCATCTCC GCATCTCG GCATCTCT 
GCATCTGA GCATCTGC GCATCTGG GCATCTGT GCATCTTA GCATCTTC GCATCTTG GCATCTTT 
GCATGAAA GCATGAAC GCATGAAG GCATGAAT GCATGACA GCATGACC GCATGACG GCATGACT 
GCATGAGA GCATGAGC GCATGAGG GCATGAGT GCATGATA GCATGATC GCATGATG GCATGATT 
GCATGCAA GCATGCAC GCATGCAG GCATGCAT GCATGCCA GCATGCCC GCATGCCG GCATGCCT 
GCATGCGA GCATGCGC GCATGCGG GCATGCGT GCATGCTA GCATGCTC GCATGCTG GCATGCTT 
GCATGGAA GCATGGAC GCATGGAG GCATGGAT GCATGGCA GCATGGCC GCATGGCG GCATGGCT 
GCATGGGA GCATGGGC GCATGGGG GCATGGGT GCATGGTA GCATGGTC GCATGGTG GCATGGTT 
GCATGTAA GCATGTAC GCATGTAG GCATGTAT GCATGTCA GCATGTCC GCATGTCG GCATGTCT 
GCATGTGA GCATGTGC GCATGTGG GCATGTGT GCATGTTA GCATGTTC GCATGTTG GCATGTTT 
GCATTAAA GCATTAAC GCATTAAG GCATTAAT GCATTACA GCATTACC GCATTACG GCATTACT 
GCATTAGA GCATTAGC GCATTAGG GCATTAGT GCATTATA GCATTATC GCATTATG GCATTATT 
GCATTCAA GCATTCAC GCATTCAG GCATTCAT GCATTCCA GCATTCCC GCATTCCG GCATTCCT 
GCATTCGA GCATTCGC GCATTCGG GCATTCGT GCATTCTA GCATTCTC GCATTCTG GCATTCTT 
GCATTGAA GCATTGAC GCATTGAG GCATTGAT GCATTGCA GCATTGCC GCATTGCG GCATTGCT 
GCATTGGA GCATTGGC GCATTGGG GCATTGGT GCATTGTA GCATTGTC GCATTGTG GCATTGTT 
GCATTTAA GCATTTAC GCATTTAG GCATTTAT GCATTTCA GCATTTCC GCATTTCG GCATTTCT 
GCATTTGA GCATTTGC GCATTTGG GCATTTGT GCATTTTA GCATTTTC GCATTTTG GCATTTTT 
GCCAAAAA GCCAAAAC GCCAAAAG GCCAAAAT GCCAAACA GCCAAACC GCCAAACG GCCAAACT 
GCCAAAGA GCCAAAGC GCCAAAGG GCCAAAGT GCCAAATA GCCAAATC GCCAAATG GCCAAATT 
GCCAACAA GCCAACAC GCCAACAG GCCAACAT GCCAACCA GCCAACCC GCCAACCG GCCAACCT 
GGACGCGA GGACGCGC GGACGCGG GGACGCGT GGACGCTA GGACGCTC GGACGCTG GGACGCTT 
GGACGGAA GGACGGAC GGACGGAG GGACGGAT GGACGGCA GGACGGCC GGACGGCG GGACGGCT 
GGACGGGA GGACGGGC GGACGGGG GGACGGGT GGACGGTA GGACGGTC GGACGGTG GGACGGTT 
GGACGTAA GGACGTAC GGACGTAG GGACGTAT GGACGTCA GGACGTCC GGACGTCG GGACGTCT 
GGACGTGA GGACGTGC GGACGTGG GGACGTGT GGACGTTA GGACGTTC GGACGTTG GGACGTTT 
GGACTAAA GGACTAAC GGACTAAG GGACTAAT GGACTACA GGACTACC GGACTACG GGACTACT 
GGACTAGA GGACTAGC GGACTAGG GGACTAGT GGACTATA GGACTATC GGACTATG GGACTATT 
GGACTCAA GGACTCAC GGACTCAG GGACTCAT GGACTCCA GGACTCCC GGACTCCG GGACTCCT 
GGACTCGA GGACTCGC GGACTCGG GGACTCGT GGACTCTA GGACTCTC GGACTCTG GGACTCTT 
GGACTGAA GGACTGAC GGACTGAG GGACTGAT GGACTGCA GGACTGCC GGACTGCG GGACTGCT 
GGACTGGA GGACTGGC GGACTGGG GGACTGGT GGACTGTA GGACTGTC GGACTGTG GGACTGTT 
GGACTTAA GGACTTAC GGACTTAG GGACTTAT GGACTTCA GGACTTCC GGACTTCG GGACTTCT 
GGACTTGA GGACTTGC GGACTTGG GGACTTGT GGACTTTA GGACTTTC GGACTTTG GGACTTTT 
GGAGAAAA GGAGAAAC GGAGAAAG GGAGAAAT GGAGAACA GGAGAACC GGAGAACG GGAGAACT 
GGAGAAGA GGAGAAGC GGAGAAGG GGAGAAGT GGAGAATA GGAGAATC GGAGAATG GGAGAATT 
GGAGACAA GGAGACAC GGAGACAG GGAGACAT GGAGACCA GGAGACCC GGAGACCG GGAGACCT 
GGAGACGA GGAGACGC GGAGACGG GGAGACGT GGAGACTA GGAGACTC GGAGACTG GGAGACTT 
GGAGAGAA GGAGAGAC GGAGAGAG GGAGAGAT GGAGAGCA GGAGAGCC GGAGAGCG GGAGAGCT 
GGAGAGGA GGAGAGGC GGAGAGGG GGAGAGGT GGAGAGTA GGAGAGTC GGAGAGTG GGAGAGTT 
GGAGATAA GGAGATAC GGAGATAG GGAGATAT GGAGATCA GGAGATCC GGAGATCG GGAGATCT 
GGAGATGA GGAGATGC GGAGATGG GGAGATGT GGAGATTA GGAGATTC GGAGATTG GGAGATTT 
GGAGCAAA GGAGCAAC GGAGCAAG GGAGCAAT GGAGCACA GGAGCACC GGAGCACG GGAGCACT 
GGAGCAGA GGAGCAGC GGAGCAGG GGAGCAGT GGAGCATA GGAGCATC GGAGCATG GGAGCATT 
GGAGCCAA GGAGCCAC GGAGCCAG GGAGCCAT GGAGCCCA GGAGCCCC GGAGCCCG GGAGCCCT 
GGAGCCGA GGAGCCGC GGAGCCGG GGAGCCGT GGAGCCTA GGAGCCTC GGAGCCTG GGAGCCTT 
GGAGCGAA GGAGCGAC GGAGCGAG GGAGCGAT GGAGCGCA GGAGCGCC GGAGCGCG GGAGCGCT 
GGAGCGGA GGAGCGGC GGAGCGGG GGAGCGGT GGAGCGTA GGAGCGTC GGAGCGTG GGAGCGTT 
GGAGCTAA GGAGCTAC GGAGCTAG GGAGCTAT GGAGCTCA GGAGCTCC GGAGCTCG GGAGCTCT 
GGAGCTGA GGAGCTGC GGAGCTGG GGAGCTGT GGAGCTTA GGAGCTTC GGAGCTTG GGAGCTTT 
GGAGGAAA GGAGGAAC GGAGGAAG GGAGGAAT GGAGGACA GGAGGACC GGAGGACG GGAGGACT 
GGAGGAGA GGAGGAGC GGAGGAGG GGAGGAGT GGAGGATA GGAGGATC GGAGGATG GGAGGATT 
GGAGGCAA GGAGGCAC GGAGGCAG GGAGGCAT GGAGGCCA GGAGGCCC GGAGGCCG GGAGGCCT 
GGAGGCGA GGAGGCGC GGAGGCGG GGAGGCGT GGAGGCTA GGAGGCTC GGAGGCTG GGAGGCTT 
GGAGGGAA GGAGGGAC GGAGGGAG GGAGGGAT GGAGGGCA GGAGGGCC GGAGGGCG GGAGGGCT 
GGAGGGGA GGAGGGGC GGAGGGGG GGAGGGGT GGAGGGTA GGAGGGTC GGAGGGTG GGAGGGTT 
GGAGGTAA GGAGGTAC GGAGGTAG GGAGGTAT GGAGGTCA GGAGGTCC GGAGGTCG GGAGGTCT 
TCTTCTGA TCTTCTGC TCTTCTGG TCTTCTGT TCTTCTTA TCTTCTTC TCTTCTTG TCTTCTTT 
TCTTGAAA TCTTGAAC TCTTGAAG TCTTGAAT TCTTGACA TCTTGACC TCTTGACG TCTTGACT 
TCTTGAGA TCTTGAGC TCTTGAGG TCTTGAGT TCTTGATA TCTTGATC TCTTGATG TCTTGATT 
TCTTGCAA TCTTGCAC TCTTGCAG TCTTGCAT TCTTGCCA TCTTGCCC TCTTGCCG TCTTGCCT 
TCTTGCGA TCTTGCGC TCTTGCGG TCTTGCGT TCTTGCTA TCTTGCTC TCTTGCTG TCTTGCTT 
TCTTGGAA TCTTGGAC TCTTGGAG TCTTGGAT TCTTGGCA TCTTGGCC TCTTGGCG TCTTGGCT 
TCTTGGGA TCTTGGGC TCTTGGGG TCTTGGGT TCTTGGTA TCTTGGTC TCTTGGTG TCTTGGTT 
TCTTGTAA TCTTGTAC TCTTGTAG TCTTGTAT TCTTGTCA TCTTGTCC TCTTGTCG TCTTGTCT 
TCTTGTGA TCTTGTGC TCTTGTGG TCTTGTGT TCTTGTTA TCTTGTTC TCTTGTTG TCTTGTTT 
TCTTTAAA TCTTTAAC TCTTTAAG TCTTTAAT TCTTTACA TCTTTACC TCTTTACG TCTTTACT 
TCTTTAGA TCTTTAGC TCTTTAGG TCTTTAGT TCTTTATA TCTTTATC TCTTTATG TCTTTATT 
TCTTTCAA TCTTTCAC TCTTTCAG TCTTTCAT TCTTTCCA TCTTTCCC TCTTTCCG TCTTTCCT 
TCTTTCGA TCTTTCGC TCTTTCGG TCTTTCGT TCTTTCTA TCTTTCTC TCTTTCTG TCTTTCTT 
TCTTTGAA TCTTTGAC TCTTTGAG TCTTTGAT TCTTTGCA TCTTTGCC TCTTTGCG TCTTTGCT 
TCTTTGGA TCTTTGGC TCTTTGGG TCTTTGGT TCTTTGTA TCTTTGTC TCTTTGTG TCTTTGTT 
TCTTTTAA TCTTTTAC TCTTTTAG TCTTTTAT TCTTTTCA TCTTTTCC TCTTTTCG TCTTTTCT 
TCTTTTGA TCTTTTGC TCTTTTGG TCTTTTGT TCTTTTTA TCTTTTTC TCTTTTTG TCTTTTTT 
TGAAAAAA TGAAAAAC TGAAAAAG TGAAAAAT TGAAAACA TGAAAACC TGAAAACG TGAAAACT 
TGAAAAGA TGAAAAGC TGAAAAGG TGAAAAGT TGAAAATA TGAAAATC TGAAAATG TGAAAATT 
TGAAACAA TGAAACAC TGAAACAG TGAAACAT TGAAACCA TGAAACCC TGAAACCG TGAAACCT 
TGAAACGA TGAAACGC TGAAACGG TGAAACGT TGAAACTA TGAAACTC TGAAACTG TGAAACTT 
TGAAAGAA TGAAAGAC TGAAAGAG TGAAAGAT TGAAAGCA TGAAAGCC TGAAAGCG TGAAAGCT 
TGAAAGGA TGAAAGGC TGAAAGGG TGAAAGGT TGAAAGTA TGAAAGTC TGAAAGTG TGAAAGTT 
TGAAATAA TGAAATAC TGAAATAG TGAAATAT TGAAATCA TGAAATCC TGAAATCG TGAAATCT 
TGAAATGA TGAAATGC TGAAATGG TGAAATGT TGAAATTA TGAAATTC TGAAATTG TGAAATTT 
TGAACAAA TGAACAAC TGAACAAG TGAACAAT TGAACACA TGAACACC TGAACACG TGAACACT 
TGAACAGA TGAACAGC TGAACAGG TGAACAGT TGAACATA TGAACATC TGAACATG TGAACATT 
TGAACCAA TGAACCAC TGAACCAG TGAACCAT TGAACCCA TGAACCCC TGAACCCG TGAACCCT 
TGAACCGA TGAACCGC TGAACCGG TGAACCGT TGAACCTA TGAACCTC TGAACCTG TGAACCTT 
TGAACGAA TGAACGAC TGAACGAG TGAACGAT TGAACGCA TGAACGCC TGAACGCG TGAACGCT 
TGAACGGA TGAACGGC TGAACGGG TGAACGGT TGAACGTA TGAACGTC TGAACGTG TGAACGTT 
TGAACTAA TGAACTAC TGAACTAG TGAACTAT TGAACTCA TGAACTCC TGAACTCG TGAACTCT 
TGAACTGA TGAACTGC TGAACTGG TGAACTGT TGAACTTA TGAACTTC TGAACTTG TGAACTTT 
TGAAGAAA TGAAGAAC TGAAGAAG TGAAGAAT TGAAGACA TGAAGACC TGAAGACG TGAAGACT 
TGAAGAGA TGAAGAGC TGAAGAGG TGAAGAGT TGAAGATA TGAAGATC TGAAGATG TGAAGATT 
TGAAGCAA TGAAGCAC TGAAGCAG TGAAGCAT TGAAGCCA TGAAGCCC TGAAGCCG TGAAGCCT 
TTTGTGAA TTTGTGAC TTTGTGAG TTTGTGAT TTTGTGCA TTTGTGCC TTTGTGCG TTTGTGCT 
TTTGTGGA TTTGTGGC TTTGTGGG TTTGTGGT TTTGTGTA TTTGTGTC TTTGTGTG TTTGTGTT 
TTTGTTAA TTTGTTAC TTTGTTAG TTTGTTAT TTTGTTCA TTTGTTCC TTTGTTCG TTTGTTCT 
TTTGTTGA TTTGTTGC TTTGTTGG TTTGTTGT TTTGTTTA TTTGTTTC TTTGTTTG TTTGTTTT 
TTTTAAAA TTTTAAAC TTTTAAAG TTTTAAAT TTTTAACA TTTTAACC TTTTAACG TTTTAACT 
TTTTAAGA TTTTAAGC TTTTAAGG TTTTAAGT TTTTAATA TTTTAATC TTTTAATG TTTTAATT 
TTTTACAA TTTTACAC TTTTACAG TTTTACAT TTTTACCA TTTTACCC TTTTACCG TTTTACCT 
TTTTACGA TTTTACGC TTTTACGG TTTTACGT TTTTACTA TTTTACTC TTTTACTG TTTTACTT 
TTTTAGAA TTTTAGAC TTTTAGAG TTTTAGAT TTTTAGCA TTTTAGCC TTTTAGCG TTTTAGCT 
TTTTAGGA TTTTAGGC TTTTAGGG TTTTAGGT TTTTAGTA TTTTAGTC TTTTAGTG TTTTAGTT 
TTTTATAA TTTTATAC TTTTATAG TTTTATAT TTTTATCA TTTTATCC TTTTATCG TTTTATCT 
TTTTATGA TTTTATGC TTTTATGG TTTTATGT TTTTATTA TTTTATTC TTTTATTG TTTTATTT 
TTTTCAAA TTTTCAAC TTTTCAAG TTTTCAAT TTTTCACA TTTTCACC TTTTCACG TTTTCACT 
TTTTCAGA TTTTCAGC TTTTCAGG TTTTCAGT TTTTCATA TTTTCATC TTTTCATG TTTTCATT 
TTTTCCAA TTTTCCAC TTTTCCAG TTTTCCAT TTTTCCCA TTTTCCCC TTTTCCCG TTTTCCCT 
TTTTCCGA TTTTCCGC TTTTCCGG TTTTCCGT TTTTCCTA TTTTCCTC TTTTCCTG TTTTCCTT 
TTTTCGAA TTTTCGAC TTTTCGAG TTTTCGAT TTTTCGCA TTTTCGCC TTTTCGCG TTTTCGCT 
TTTTCGGA TTTTCGGC TTTTCGGG TTTTCGGT TTTTCGTA TTTTCGTC TTTTCGTG TTTTCGTT 
TTTTCTAA TTTTCTAC TTTTCTAG TTTTCTAT TTTTCTCA TTTTCTCC TTTTCTCG TTTTCTCT 
TTTTCTGA TTTTCTGC TTTTCTGG TTTTCTGT TTTTCTTA TTTTCTTC TTTTCTTG TTTTCTTT 
TTTTGAAA TTTTGAAC TTTTGAAG TTTTGAAT TTTTGACA TTTTGACC TTTTGACG TTTTGACT 
TTTTGAGA TTTTGAGC TTTTGAGG TTTTGAGT TTTTGATA TTTTGATC TTTTGATG TTTTGATT 
TTTTGCAA TTTTGCAC TTTTGCAG TTTTGCAT TTTTGCCA TTTTGCCC TTTTGCCG TTTTGCCT 
TTTTGCGA TTTTGCGC TTTTGCGG TTTTGCGT TTTTGCTA TTTTGCTC TTTTGCTG TTTTGCTT 
TTTTGGAA TTTTGGAC TTTTGGAG TTTTGGAT TTTTGGCA TTTTGGCC TTTTGGCG TTTTGGCT 
TTTTGGGA TTTTGGGC TTTTGGGG TTTTGGGT TTTTGGTA TTTTGGTC TTTTGGTG TTTTGGTT 
TTTTGTAA TTTTGTAC TTTTGTAG TTTTGTAT TTTTGTCA TTTTGTCC TTTTGTCG TTTTGTCT 
TTTTGTGA TTTTGTGC TTTTGTGG TTTTGTGT TTTTGTTA TTTTGTTC TTTTGTTG TTTTGTTT 
TTTTTAAA TTTTTAAC TTTTTAAG TTTTTAAT TTTTTACA TTTTTACC TTTTTACG TTTTTACT 
TTTTTAGA TTTTTAGC TTTTTAGG TTTTTAGT TTTTTATA TTTTTATC TTTTTATG TTTTTATT 
/;



# how many fasta files are provided?
my $listlength = `wc $list`;
my @listlength = split " ", $listlength;
if ($listlength[0] > $#barcodes-1){
  print STDERR "We have not implemented enough artificial barcodes to properly handle your multiple fasta file input to the pipeline.\nApologies!!\n"; 
  exit(1);
}

# check for quality filelist
if ($quallist =~ /[A-Za-z0-9]/){
  print "looking at quallist b/c I think it exists!\n";
  my $qlistlength = `wc $list`;
  my @qlistlength = split " ", $listlength;
  if($listlength[0] != $qlistlength[0]){
    print STDERR "The number of input fasta files is not the same as the number of quality files!\nCheck your inputs.\n";
    exit(1);
  }
}


# first let's handle the case where we have a Qiime-formatted mapping file:
if ($listlength[0] == 1){
  my $file = `cat $list`;
  chomp($file);
  copy($file, $finalseqfile);

  # quality file
  if ($quallist =~ /[A-Za-z0-9]/){
    my $qfile = `cat $quallist`;
    chomp($qfile);
    copy($qfile, $finalqualfile);
  }else{
    open Q, ">$finalqualfile"; 
    close Q;
  }

  # correct Qiime-formatted mapping file if necessary
  qiimemapCorrection($mapfile);
  copy($mapfile, $finalmapfile);
  print STDOUT "One fasta file detected. We assume this file is barcoded to determine samples and also that the mapping file provided in formatted for Qiime.\n"; 
  exit(0);
}

#  otherwise we've got multiple fasta files
#  we assume that these files are trimmed of barcodes/primers and that each file
#  represents a different specific sample.
my $catstr = `cat $list`;
my @catstr = split "\n", $catstr;
open SEQ, ">$finalseqfile" or die;
open QUAL, ">$finalqualfile" or die;


for my $i (0 .. ($listlength[0]-1)){
  my $bc = $barcodes[$i]; # this is the associated barcode for the sample
  # print "$bc\n";

  # do some processing of the filename to get the prefix
  # and store the associated barcode
  my @line = split /\//, $catstr[$i];
  $data{$line[$#line]} = $bc;
  my @linesplit = split /\./, $line[$#line];
  my $fileprefix = join(".", @linesplit[0..($#linesplit-1)]);

  # open and process this file
  open IN, "$catstr[$i]" or die "Can't open $catstr[$i] for preprocessing!\n";
  my $seq = "";
  my $seqname = "";
  my $seqcount = 1;
  my $fL = 70;
  while(<IN>){
    chomp($_);
    if ($_ =~ /^>/){ # we've reached a new sequence in this fasta file
      my @A = split " ", $_;
      if ($seq ne ""){
        print SEQ ">$fileprefix\_$seqname\n";
        my $tmp  = $bc;
        $tmp    .= $ARTIFICIAL_PRIMER;
        $tmp    .= $seq;
 
        for (my $i = 0; $i<length($tmp); $i+=$fL){
          my $substr = substr($tmp, $i, $fL);
          print SEQ "$substr\n";
        }
        $seqcount++;
      }
      $seqname = substr($A[0],1);
      $seq = "";
    }else{ 
      $seq .= "$_";
    }
  }
  close IN;

  print SEQ ">$fileprefix\_$seqname\n"; 
  my $tmp2 = $bc;
  $tmp2   .= $ARTIFICIAL_PRIMER;
  $tmp2   .= $seq;

  for (my $i = 0; $i<length($tmp2); $i+=$fL){
    my $substr = substr($tmp2, $i, $fL);
    print SEQ "$substr\n";
  }
  # end of this file

  # Now if there are quality scores you should be able to go through the list
  # and find the matching file name
  if ($quallist =~ /[A-Za-z0-9]/){
    my $qcatstr = `cat $quallist`;
    my @qcatstr = split "\n", $qcatstr;

    # search the list
    my $targetQualFile = "";
    my $targetQualPrefix = "";
    foreach my $qf (@qcatstr){
      # print "$qf\n";
      my @qline = split /\//, $qf;
      my @qlinesplit = split /\./, $qline[$#qline];
      my $qfprefix = join(".", @qlinesplit[0..($#qlinesplit-1)]);
      
      if ($fileprefix eq $qfprefix){ # we found a match
        $targetQualFile = $qf;
        $targetQualPrefix = $qfprefix;
        last;  
      }
    }

    if ($targetQualFile eq ""){
      print STDERR "Error: No quality score file could be found for fasta file $fileprefix!\n";
      exit(1);
    } 
    
    # go through this matching qual file        
    open QF, "$targetQualFile" or die "Cannot open $targetQualFile!\n"; 
    $seq = "";
    $seqname = "";
    $seqcount = 1;
    $fL = 1e10;
    while(<QF>){
      chomp($_);
      if ($_ =~ /^>/){ # we've reached a new sequence in this fasta file
        my @A = split " ", $_;
        if ($seq ne ""){
          print QUAL ">$fileprefix\_$seqname\n";
          my $tmp  = $ARTIFICIAL_QUALSTR;
          $tmp    .= " $seq";

          for (my $i = 0; $i<length($tmp); $i+=$fL){
            my $substr = substr($tmp, $i, $fL);
            print QUAL "$substr\n";
          }
          $seqcount++;
        }
        $seqname = substr($A[0],1);
        $seq = "";
      }else{
        $seq .= " $_";
      }
    } 
    close QF; #end of file    

    print QUAL ">$fileprefix\_$seqname\n";
    $tmp2   = $ARTIFICIAL_QUALSTR;
    $tmp2  .= " $seq";
    for (my $i = 0; $i<length($tmp2); $i+=$fL){
      my $substr = substr($tmp2, $i, $fL);
      print QUAL "$substr\n";
    }
  }
}
close SEQ;
close QUAL;



# now create the corresponding mapping file for Qiime
# and be sure it ends in Description
my $qiimeDescCk = 1;
open MAP, ">$finalmapfile" or die;
open IMAP, "$mapfile" or die "Can't open $mapfile!!\n";
while(<IMAP>){
  chomp($_);
  my @A = split "\t", $_;
  if ($_ =~ /^#/){
    print MAP "#SampleID\tBarcodeSequence\tLinkerPrimerSequence";
    for my $j (1 .. $#A){
      print MAP "\t$A[$j]";
    }
    if ($A[$#A] ne "Description"){
      $qiimeDescCk = 0;
      print MAP "\tDescription";
    }
    print MAP "\n";
  }else{
    my @B    = split /\./,$A[0];
    my $mapprefix = join(".", @B[0..($#B-1)]);
    print MAP "$mapprefix\t$data{$A[0]}\t$ARTIFICIAL_PRIMER";
    for my $j (1 .. $#A){
      print MAP "\t$A[$j]";
    }
    if ($qiimeDescCk == 0){
      print MAP "\tnone";
    } 
    print MAP "\n";
  }
}
close IMAP;
close MAP;

exit(0);


# takes a qiime formatted mapping file and adds
# a "Description" column if it's not there.
sub qiimemapCorrection
{
   my ($qm) = @_;
   open IN, "$qm" or die "Can't open $qm for reading!\n";
   my $mapfilestring = "";
   my $ck = 0;
   while(<IN>){
     chomp($_);
     if ($ck == 0){ #header line       
       my @A = split "\t", $_;
       if ($A[$#A] eq "Description"){ # then we're good
         $ck = 2;       
         last;
       }else{
         $ck = 1;
         $mapfilestring .= "$_\tDescription";
       }
     }else{
         $mapfilestring .= "\n$_\tnone";
     }
   }
   close IN;

  if ($ck == 2){
    print STDOUT "Qiime-formatted mapping file appears correct ...\n";
    return;
  }else{ # we hit a problem and need to edit the mapping file
    open OUT, ">$qm" or die "Can't open $qm for editing!!\n";
    print OUT "$mapfilestring";
    close OUT;
    print STDOUT "Correcting Qiime-formatted mapping file...(must end with the column Description)\n";
    return;
  }
}




