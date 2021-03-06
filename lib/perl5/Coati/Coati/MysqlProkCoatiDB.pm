package Coati::Coati::MysqlProkCoatiDB;

use strict;
use base qw(Coati::Coati::ProkCoatiDB Coati::MysqlHelper);

#################################

sub _connect {
    my ($self, $hostname, @args) = @_;
    
    $self->{_logger}->debug("Args: ",join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    #
    # Connect to the MySQL database
    Coati::MysqlHelper::connect($self);
}

sub do_set_textsize {
    my ($self, $size) = @_;
    return undef;
}

sub get_seq_id_to_gene_features {
    my ($self, $seq_id, $feat_type) = @_;
    
    $self->{_logger}->debug("Args: ",join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    
    my $query = "SELECT a.feat_name, a.asmbl_id, d.name, a.end5, a.end3, 0 as strand, f.name, '', a.feat_type ".
                "FROM asm_feature a, stan s, common.feat_type f, asmbl_data d ".
                "WHERE s.iscurrent = 1 ".
                "AND a.asmbl_id = $seq_id ".
                "AND s.asmbl_id = a.asmbl_id ".
		"AND s.asmbl_data_id = d.id ".
		"AND a.feat_type = f.feat_type ";
    
    if($feat_type ne "") {
	$query .= "AND a.feat_type = '$feat_type' ";
    }

    $query .= "ORDER BY a.end5 DESC "; 

    return $self->_get_results_ref($query);
}

#################################

1;
