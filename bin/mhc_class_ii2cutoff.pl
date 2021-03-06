#!/usr/bin/perl -w
use strict;

####Convert mhc_class_i raw output to 2 column table of sequence IDs and number of peptides from that ID after cutoff---->This has been omited
###Rewrites raw output to replace sequence numbers with IDs
##Writes significant sequence ID and peptides with IC50 values

my $input_fsa = $ARGV[0];
my $mhc_out = $ARGV[1];
#my $mhc_i2table = $ARGV[2];
my $ct=0;
my (%table,%peptides,%seq_ids,%hash,%coords);

my $ic50  = $mhc_out;
$ic50 =~ s/\.out$//;
$ic50 .= ".cutoff";

open (my $fh, "<", $input_fsa) || die "Couldn't open mhc's original input fasta file:$!\n";

while (<$fh>) {
    if ($_ =~ /^>/) {
	my $seq = $_;
	$seq =~ s/^>//;
	$seq =~ s/\s+$//g;
	$seq =~ s/\..*\..*\..*$//;
	$ct++;
	$seq_ids{$ct} = $seq;
    }
}

close $fh || die "$!\n";

###################################

open (my $fh2, "<", $mhc_out) || die "Couldn't open mhc raw output:$!\n";

while (<$fh2>) {
    if ($. == 1 && $_ =~ /allele/) {next;} else {
		print STDERR "Potentially blank file detected.\n";
	}
    my @cols = split(/\s+/,$_);
	if ($cols[5] <= 5.00) {
	    if ($seq_ids{$cols[1]}) {
		$peptides{$cols[4]}{$seq_ids{$cols[1]}.$cols[2]} = $seq_ids{$cols[1]};   ###Peptide -> SeqID
		$hash{$cols[4]} = $cols[13];   #."_nM";           ###Peptide -> IC50
		$coords{$cols[4]}{$seq_ids{$cols[1]}.$cols[2]} = "$cols[2]\t$cols[3]\t$cols[0]";   ###Peptide -> Coordinates and allele
	    }
	}
}

close $fh2 || die "$!\n";

open (my $fh3, ">", $ic50) || die "Couldn't open mhc_class_i cut-off filtered data file to write:$!\n";

foreach my $pep (keys %peptides) {
	foreach my $seq (keys %{$peptides{$pep}}) {
	   	print $fh3 "$peptides{$pep}{$seq}\t$pep\t$hash{$pep}\t$coords{$pep}{$seq}\n";
	}
}

close $fh3 || die "$!\n";

####################################

#open (my $fh4, ">", $mhc_i2table) || die "Couldn't open mhc_class_i2table file to write:$!\n";

#foreach (keys %peptides) {
#	if ($table{$peptides{$_}}) {
#		$table{$peptides{$_}} += 1;
#	} else {
#		$table{$peptides{$_}} += 1;
#	}
#}

#foreach (keys %table) {
#	print $fh4 "$_\t$table{$_}\n";
#}

#close $fh4 || die "$!\n";

###################################

open (my $fh5, "<", $mhc_out) || die "Couldn't open mhc raw output:$!\n";

my @lines = <$fh5>;

close $fh5 || die "$!\n";

open (my $fh6, ">" ,$mhc_out) || die "Couldn't open mhc raw output:$!\n";

foreach (@lines) {

	if ($_ =~ /seq_num/) {
		my $line = $_;
		$line =~ s/seq_num/seq_ids/;
    	print $fh6 "$line\n";
	} else {
		my @split = split(/\s+/,$_);
		$split[1] = $seq_ids{$split[1]};
		my $line = join("\t",@split);
		print $fh6 "$line\n";
	}

}

close $fh6 ||die "$!\n";













