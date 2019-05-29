#!/usr/bin/perl -w
use strict;

my $mhc_i_exec = $ARGV[0];
my $i_file_path = $ARGV[1];
my @cmds;

my @consensus_alleles = qw(HLA-A*01:01 HLA-A*02:01 HLA-A*02:02 HLA-A*02:03 HLA-A*02:06 HLA-A*02:11 HLA-A*02:12 HLA-A*02:16 HLA-A*02:17 HLA-A*02:19 HLA-A*02:50 HLA-A*03:01 HLA-A*11:01 HLA-A*23:01 HLA-A*24:02 HLA-A*24:03 HLA-A*25:01 HLA-A*26:01 HLA-A*26:02 HLA-A*26:03 HLA-A*29:02 HLA-A*30:01 HLA-A*30:02 HLA-A*31:01 HLA-A*32:01 HLA-A*32:07 HLA-A*32:15 HLA-A*33:01 HLA-A*66:01 HLA-A*68:01 HLA-A*68:02 HLA-A*68:23 HLA-A*69:01 HLA-A*80:01 HLA-B*07:02 HLA-B*08:01 HLA-B*08:02 HLA-B*08:03 HLA-B*14:02 HLA-B*15:01 HLA-B*15:02 HLA-B*15:03 HLA-B*15:09 HLA-B*15:17 HLA-B*18:01 HLA-B*27:05 HLA-B*27:20 HLA-B*35:01 HLA-B*35:03 HLA-B*38:01 HLA-B*39:01 HLA-B*40:01 HLA-B*40:02 HLA-B*40:13 HLA-B*42:01 HLA-B*44:02 HLA-B*44:03 HLA-B*45:01 HLA-B*46:01 HLA-B*48:01 HLA-B*51:01 HLA-B*53:01 HLA-B*54:01 HLA-B*57:01 HLA-B*58:01 HLA-B*73:01 HLA-B*83:01 HLA-C*03:03 HLA-C*04:01 HLA-C*05:01 HLA-C*06:02 HLA-C*07:01 HLA-C*07:02 HLA-C*08:02 HLA-C*12:03 HLA-C*14:02 HLA-C*15:02 HLA-E*01:01);

my @peptide_lengths = qw( 9 ); #8 10 11 12 13 14);

foreach my $allele (@consensus_alleles) {
   foreach my $l (@peptide_lengths) {
	push (@cmds, "$mhc_i_exec\tconsensus\t$allele\t$l\t$i_file_path");
   }
}

foreach (@cmds) {
	print "$_\n";
}
