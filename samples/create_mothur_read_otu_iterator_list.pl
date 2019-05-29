#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
BEGIN{foreach (@INC) {s/\/usr\/local\/packages/\/local\/platform/}};
use lib (@INC,$ENV{"PERL_MOD_DIR"});
no lib "$ENV{PERL_MOD_DIR}/i686-linux";
no lib ".";

=head1 NAME

create_mothur_read_otu_iterator_list.pl - Default output is a workflow iterator that can be used to iterator over input for read.otu

=head1 SYNOPSIS

USAGE: ./create_mothur_read_otu_iterator_list.pl --otu_file=/path/to/otu/file --otu_file_list=/path/to/otu/file/list
                                                 --groups_file_list=/path/to/name/files/list --output=/path/to/output/iterator
                                               
=head1 OPTIONS

B<--otu_file, -i>
    A single OTU file

B<--otu_file_list, -il>
    A list of OTU files.

B<--groups_file_list, -n>
    A list of mothur trim.seqs generated group files.
       
B<--output, -o>
    Desired path to output iterator file
    
B<--log, -l>
    Optional. Log file.
    
B<--debug, -d>
    Optional. Debug level.
    
B<--help>
    Print perldocs for this script.
    
=head1 DESCRIPTION

Creates an ergatis/workflow iterator list file for a distributed mothur read.otu job. The iterator contains all the parameters needed to run 
unique.seqs successfully, attempting to pair up groups of files (OTU file - group file) based of the base filename prefix
(e.x. AMP01_LUNG.trim.list - AMP01_LUNG.trim.group would be grouped together as they all carry the AMP01_LUNG prefix).

=head1 INPUT

The only mandatory input file is the OTU file. Optionanlly a list of group files generated by trim.seqs can also be included.
                    
=head1 OUTPUT

An ergatis iterator list.

=head1 CONTACT

    Cesar Arze
    carze@som.umaryland.edu
    
=cut

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use Pod::Usage;
use File::Basename;
use Ergatis::Logger;
umask(0000);
my $logger;

my %options = &parse_options();
my $otu_file = $options{'otu_file'};
my $otu_list = $options{'otu_file_list'};
my $groups_list = $options{'groups_file_list'};
my $output = $options{'output'};

# Parse input...
my @otu_files = parse_otu_files($otu_file, $otu_list);
my $group_files = parse_list_file($groups_list) if defined ($options{'groups_file_list'});

open (OUTFILE, "> $output") or $logger->logdie("Could not open output iterator $output for writing: $!");
print OUTFILE '$;I_FILE_BASE$;' . "\t" .
              '$;I_FILE_NAME$;' . "\t" .
              '$;I_FILE_PATH$;' . "\t" .
              '$;GROUP_FILE$;' . "\n";
                            
# Iterate over all sequence files and if a corresponding name file exists print it out
# to the iterator list as well.                            
foreach my $otu (@otu_files) {
    my $filename = basename($otu);
    my $file_base = fileparse($otu, '\.(.*)');
    my $group = $group_files->{$file_base};
    if (!defined($group)){
      $group = `cat $groups_list`;
      chomp($group);
    }
    
    print OUTFILE "$file_base\t$filename\t$otu\t$group\n";    
}              

close OUTFILE;
              
#########################################################################
#                                                                       #
#                           SUBROUTINES                                 #
#                                                                       #
#########################################################################

## Parses a list file, creating a hash containing file prefix as key and 
## absolute filename as value.
sub parse_list_file {
    my $file = shift;
    my $files = ();
    
    open (FILELIST, $file) or $logger->logdie("Could not open list $file: $!");
    while (my $line = <FILELIST>) {
        chomp ($line);
        my $file_prefix = fileparse($line, '\.(.*)');
        
        if ( &verify_file($line) && !( exists($files->{$file_prefix}) ) ) {
            $files->{$file_prefix} = $line;
        } else {
            $logger->logwarn("Duplicate file prefix found for file $line");
        }
    }
    
    close (FILELIST);   
    return $files;
}
                 
# Parses list of sequence files returning an array containing absolute
# paths to each sequence file.                 
sub parse_otu_files {
    my ($otu_file, $otu_list) = @_;
    my @files;
    
    ## Handle a single sequence file being passed in...
    push (@files, $otu_file) if ( defined($otu_file) && &verify_file($otu_file) );
    if ( defined($otu_list) && &verify_file($otu_list) ) {
        open (OTULIST, $otu_list) or $logger->logdie("Could not open sequence file list $otu_list: $!");
        
        while (my $line = <OTULIST>) {
            chomp ($line);
            push (@files, $line) if ( &verify_file($line) );
        }
        
        close (OTULIST);
    }
    
    $logger->logdie("No OTU files found in input provided.") if (scalar @files == 0);
    return @files;
}                 

# Verifies that a file exists, is readable and is not zero-content.
sub verify_file {
    my @files = @_;
    
    foreach my $file (@files) {
        next if ( (-e $file) && (-r $file) && (-s $file) );
        
        if      (!-e $file) { $logger->logdie("File $file does not exist")   }
        elsif   (!-r $file) { $logger->logdie("File $file is not readable")  }
        elsif   (!-s $file) { $logger->logdie("File $file has zero content") }
    }
    
    return 1;
}
                    
sub parse_options {
    my %opts = ();
    
    GetOptions(\%opts,
                'otu_file|i=s',
                'otu_file_list|a=s',
                'groups_file_list|n=s',
                'output|o=s',
                'log|l=s',
                'debug|d=s',
                'help') || pod2usage();
       
    if ($opts{'help'}) {
        pod2usage ( { -exitval => 0, -verbose => 2, -output => \*STDERR } );
    }
    
    ## Initialize and configure logging...
    my $logfile = $opts{'log'} || Ergatis::Logger::get_default_filename();
    my $debug = $opts{'debug'} ||= 4;
    $logger = new Ergatis::Logger( 'LOG_FILE'   =>  $logfile,
                                   'LOG_LEVEL'  =>  $debug );
    $logger = Ergatis::Logger::get_logger();
   
    ## Check to make sure certain parameters are defined...
    defined ($opts{'output'}) || $logger->logdie("Please specify an output iterator file.");
                       
    return %opts;                
}                                                                                        
