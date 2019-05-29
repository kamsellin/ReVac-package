#!/usr/local/bin/perl

=head1 NAME

clusterStatistics.pl - Generate cluster member statistics

=head1 SYNOPSIS

=head1 OPTIONS

=over 8

=item B<--username,-U>
    
    Database username

=item B<--password,-P>
    
    Database password

=item B<--database,-D>
    
    Target chado database 

=item B<--analysis_id>
    
    The analysis_id of the cluster analysis to be evaluated

=item B<--debug_level,-d>

    Optional: Coati::Logger log4perl logging level.  Default is 0

=item B<--man,-m>

    Display the pod2usage page for this utility

=item B<--outfile>

    Optional: Output file to which evaluation results will be written  (default is /tmp/mapClusters.pl.out)

=item B<--help,-h>

    Print this help

=back

=head1 DESCRIPTION

    clusterStatistics.pl - Generate statistics for the cluster members belonging to the cluster set associated with the specified analysis_id

    Assumptions:
    1. User has appropriate permissions (to execute script, access chado database, write to output directory).
    2. Target chado database already contains all reference features (necessary to build feature and organism lookups) Review and execute assertClustersDisjoint.pl if required.
    3. Target chado database contains the necessary controlled vocabulary terms: "match" etc.
    4. All software has been properly installed, all required libraries are accessible.


=cut

use strict;
use File::Basename;
use File::Path;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use Data::Dumper;
use Prism::DataMining::Clustering::Cluster::Protein::Analyzer;
use Coati::Logger;

use constant DEFAULT_USERNAME => 'access';
use constant DEFAULT_PASSWORD => 'access';
use constant DEFAULT_SERVER => 'SYBPROD';
use constant DEFAULT_VENDOR => 'Sybase';

use constant DEFAULT_MIN_CLUSTER_SIZE => 5;

$|=1; ## do not buffer output stream

## Parse command line options
my ($username, $password, $outfile, $database, $debug_level, $help,
    $logfile, $man, $server, $vendor, $analysis_id, $minClusterSize);

my $results = GetOptions (
			  'username|U=s'        => \$username, 
			  'password|P=s'        => \$password,
			  'outfile=s'           => \$outfile,
			  'database|D=s'        => \$database,
			  'logfile|l=s'         => \$logfile,
			  'debug_level|d=s'     => \$debug_level, 
			  'help|h'              => \$help,
			  'man|m'               => \$man,
			  'analysis_id=s'       => \$analysis_id,
			  'vendor=s'            => \$vendor,
			  'min_cluster_size=s'  => \$minClusterSize,
			  );

&checkCommandLineArguments();

my $logger = &getLogger();

my $analyzer = new Prism::DataMining::Clustering::Cluster::Protein::Analyzer(username => $username,
									     password => $password,
									     server   => $server,
									     database => $database,
									     vendor   => $vendor,
									     min_count => $minClusterSize);
if (!defined($analyzer)){
    die "Could not instantiate Prism::DataMining::Clustering::Cluster::Protein::Analyzer";
}

$analyzer->generateReport(analysis_id => $analysis_id,
			  outfile => $outfile);

print "$0 execution completed\n";
print "The log file is '$logfile'\n";
print "The output file is '$outfile'\n";
exit(0);

##-------------------------------------------------------------------
##
##      END OF MAIN  -- SUBROUTINES FOLLOW
##
##-------------------------------------------------------------------

sub checkCommandLineArguments {

    
    if ($man){
	&pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }
    
    if ($help){
	&pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    my $fatalCtr=0;

    if (!defined($database)){
	print STDERR "--database was not specified\n";
	$fatalCtr++;
    }

    if (!defined($analysis_id)){
	print STDERR "--analysis_id was not specified\n";
	$fatalCtr++;
    }

    if ($fatalCtr> 0 ){
	die "Required command-line arguments were not specified\n";
    }

    if (!defined($username)){
	$username = DEFAULT_USERNAME;
	print STDERR "--username was not specified and ".
	"therefore was set to '$username'\n";
    }

    if (!defined($password)){
	$password = DEFAULT_PASSWORD;
	print STDERR "--password was not specified and ".
	"therefore was set to '$password'\n";
    }

    if (!defined($server)){
	$server = DEFAULT_SERVER;
	print STDERR "--server was not specified and ".
	"therefore was set to '$server'\n";
    }

    if (!defined($vendor)){
	$vendor = DEFAULT_VENDOR;
	print STDERR "--vendor was not specified and ".
	"therefore was set to '$vendor'\n";
    }

    if (!defined($minClusterSize)){
	$vendor = DEFAULT_MIN_CLUSTER_SIZE;
	print STDERR "--min_cluster_size was not specified and ".
	"therefore was set to '$minClusterSize'\n";
    }

    if (!defined($logfile)){
	$logfile = '/tmp/' . File::Basename::basename($0) . '.log';
	print STDERR "--logfile was not specified and ".
	"therefore was set to '$logfile'\n";
    }

    if (!defined($outfile)){
	$outfile = '/tmp/' . File::Basename::basename($0) . '.out';
	print STDERR "--outfile was not specified and ".
	"therefore was set to '$outfile'\n";
    }
}

sub getLogger {

    my $mylogger = new Coati::Logger('LOG_FILE'=>$logfile,
				     'LOG_LEVEL'=>$debug_level);
    
    if (!defined($mylogger)){
	die "mylogger was not defined";
    }

    my $logger = Coati::Logger::get_logger(__PACKAGE__);

    if (!defined($logger)){
	die "logger was not defined";
    }


    return $logger;
}
