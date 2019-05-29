package Coati::Coati::MysqlChadoCoatiDB;

use strict;
use base qw(Coati::Coati::ChadoCoatiDB Coati::MysqlHelper);

###################################

sub _connect {
    my ($self, $hostname, @args) = @_;
    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    Coati::MysqlHelper::connect($self);
}

sub do_set_textsize {
    my ($self, $size) = @_;
    return undef;
}
sub do_update_asm_feature {
    my ($self, $gene_id, $feat_ref, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    $db = $self->{_db} if (!$db);

    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @cd_id = $self->get_cv_term('CDS');
    my @pr_id = $self->get_cv_term('polypeptide', 'SO');
	
    if (defined($feat_ref->{'end5'}) || defined($feat_ref->{'end3'})) {
		my $query = "UPDATE $db..featureloc fl, $db..feature t, $db..feature a ".
			        "SET fl.fmin = $feat_ref->{'end5'}, fl.fmax = $feat_ref->{'end3'} ".
					"WHERE t.uniquename = ? ".
					"AND t.feature_id = fl.feature_id ".
					"AND fl.srcfeature_id = a.feature_id ".
					"AND a.type_id = $as_id[0][0] ".
					"AND t.type_id = $tr_id[0][0] ";
		
		if($self->{_seq_id}) {
			$query .= "AND a.uniquename = '$self->{_seq_id}' ";
		}

		$self->_set_values($query, $gene_id);
    }

    if (defined($feat_ref->{'sequence'})) {
		my $query = "UPDATE $db..feature c, $db..feature t, $db..feature a, $db..featureloc fl, $db..feature_relationship tc ".
                    "SET c.residues = \"$feat_ref->{'sequence'}\" ".
					"WHERE t.uniquename = ? ".
					"AND t.feature_id = fl.feature_id ".
					"AND fl.srcfeature_id = a.feature_id ".
					"AND t.feature_id = tc.object_id ".
					"AND tc.subject_id = c.feature_id ".
					"AND c.type_id = $cd_id[0][0] ".
					"AND a.type_id = $as_id[0][0] ".
					"AND t.type_id = $tr_id[0][0] ";
		
		if($self->{_seq_id}) {
			$query .= "AND a.uniquename = '$self->{_seq_id}' ";
		}
		
		$self->_set_values($query, $gene_id);
    }

    if (defined($feat_ref->{'protein'})) {
		my $query = "UPDATE $db..feature p, $db..feature t, $db..feature c, $db..feature a, $db..featureloc fl, $db..feature_relationship tc, $db..feature_relationship cp ".
			        "SET p.residues = \"$feat_ref->{'protein'}\" ".
					"WHERE t.uniquename = ? ".
					"AND t.feature_id = fl.feature_id ".
					"AND fl.srcfeature_id = a.feature_id ".
					"AND t.feature_id = tc.object_id ".
					"AND tc.subject_id = c.feature_id ".
					"AND c.feature_id = cp.object_id ".
					"AND cp.subject_id = p.feature_id ".
					"AND c.type_id = $cd_id[0][0] ".
					"AND p.type_id = $pr_id[0][0] ".
					"AND a.type_id = $as_id[0][0] ".
					"AND t.type_id = $tr_id[0][0] ";
		
		if($self->{_seq_id}) {
			$query .= "AND a.uniquename = '$self->{_seq_id}' ";
		}
		
        $self->_set_values($query, $gene_id);
    }
}

sub do_update_comment {
    my ($self, $gene_id, $comment, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @co_id = $self->get_cv_term('comment', 'annotation_attributes.ontology');
    my @feature_id = $self->get_feature_id($gene_id);
    my $delete_row = 1 if($comment eq "");

    if($comment eq "NULL") {
    $comment = "";
    }

    if(!$self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $co_id[0][0])) {
    $self->do_insert_comment($gene_id, $comment, $db);
    }
    elsif($self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $co_id[0][0]) && $delete_row) {
    $self->do_delete_comment($gene_id, $comment, $db);
    }
    else {
    my $query = "UPDATE $db..featureprop fp,$db..feature a, $db..feature t, $db..featureloc fl SET ".
                "fp.value = \"$comment\" ".  ### update comment
            "WHERE t.uniquename = '$gene_id' ".
            "AND t.feature_id = fl.feature_id ".
            "AND fl.srcfeature_id = a.feature_id ".
            "AND t.feature_id = fp.feature_id ".
            "AND fp.type_id = $co_id[0][0] ".
            "AND a.type_id = $as_id[0][0] ".
            "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
    }
}

sub do_update_public_comment {
    my ($self, $gene_id, $public_comment, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @pc_id = $self->get_cv_term('public_comment');
    my @feature_id = $self->get_feature_id($gene_id);
    my $delete_row = 1 if($public_comment eq "");

    if($public_comment eq "NULL") {
    $public_comment = "";
    }

    if(!$self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $pc_id[0][0]) && !$delete_row) {
    $self->do_insert_public_comment($gene_id, $public_comment, $db);
    }
    elsif($self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $pc_id[0][0]) && $delete_row) {
    $self->do_delete_public_comment($gene_id, $public_comment, $db);
    }
    else {
    my $query = "UPDATE $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl SET ".
                "fp.value = \"$public_comment\" ".  ### update public comment
            "WHERE t.uniquename = '$gene_id' ".
            "AND t.feature_id = fl.feature_id ".
            "AND fl.srcfeature_id = a.feature_id ".
            "AND t.feature_id = fp.feature_id ".
            "AND fp.type_id = $pc_id[0][0] ".
            "AND a.type_id = $as_id[0][0] ".
            "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
    }
}

sub do_update_ec_number {
    my ($self, $gene_id, $ec_number, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');

    # Get the feature_id for the given gene_id
    my @feature_id = $self->get_feature_id($gene_id);

	# delete all current EC numbers
	my $query = "SELECT fc.feature_cvterm_id ".
		"FROM cvterm_dbxref cd, feature t, feature_cvterm fc, cvterm c, cv ".
		"WHERE t.uniquename = '$gene_id' ".
		"AND t.feature_id = fc.feature_id ".
		"AND fc.cvterm_id = c.cvterm_id ".
		"AND c.cv_id = cv.cv_id ".
		"AND cv.name = 'EC' ".
		"AND fc.cvterm_id = cd.cvterm_id ";
	
	my $res = $self->_get_results_ref($query);
	for(my $i=0; $i<@$res; $i++) {
		my $feature_cvterm_id = $res->[$i][0];
		
		# delete the EC number by removing the link in the cvterm_dbxref table
		my $delete_q = "DELETE FROM feature_cvterm ".
			           "WHERE feature_cvterm_id = $feature_cvterm_id ";
		
		$self->_set_values($delete_q);
	}
	

	# insert new/updated EC numbers
	unless($ec_number eq "DELETE") {
		
		my @ec_nums = split('\s+',$ec_number);
		foreach my $ec_num ( sort{$a <=> $b} @ec_nums) {
			
			# Get the cvterm_id for the given EC number
			my $ec_query = "SELECT c.cvterm_id ".
				"FROM cv, cvterm c, cvterm_dbxref cd, dbxref d ".
				"WHERE d.accession = '$ec_num' ".
				"AND d.dbxref_id = cd.dbxref_id ".
				"AND cd.cvterm_id = c.cvterm_id ".
				"AND c.cv_id = cv.cv_id ".
				"AND cv.name = 'EC' ";
			
			my $res = $self->_get_results_ref($ec_query);
			my $ec_cv_id = $res->[0][0];
			
		    if($ec_cv_id eq ''){ # if the EC number is not valid then return -1.
			$self->{_querylogger}->logdie("EC Number not found in the database.%%Invalid EC Number%%The EC number you attempted to insert ".
						      "might have been entered incorrectly or does not exist in the database.  If you are sure ".
						      "the EC number you entered is correct, please contact Michelle Giglio ( mgiglio at som.umaryland.edu) so we can update the database. ".
						      "%%$DBI::errstr%%$self->{_db}%%$ec_query%%%%");
			
		    }else{# insert new EC number if it is valid
			      my $new_fc_id  = $self->get_auto_incremented_id('feature_cvterm', 'feature_cvterm_id');
			      my $insert_q = "INSERT feature_cvterm (feature_cvterm_id, feature_id, cvterm_id, pub_id, is_not) ".
				  "VALUES ($new_fc_id, $feature_id[0][0], $ec_cv_id, 1, 0) ";
			      
			      $self->_set_values($insert_q);
			  }
		}
	    }

}

sub do_update_assignby {
    my ($self, $gene_id, $assignby, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @ab_id = $self->get_cv_term('assignby');
    my @feature_id = $self->get_feature_id($gene_id);

    if(!$self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $ab_id[0][0])) {
    $self->do_insert_assignby($gene_id, $assignby, $db);
    }
    else {
    my $query = "UPDATE $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl SET ".
                "fp.value = '$assignby' ".  ### update assignby
            "WHERE t.uniquename = '$gene_id' ".
            "AND t.feature_id = fl.feature_id ".
            "AND fl.srcfeature_id = a.feature_id ".
            "AND t.feature_id = fp.feature_id ".
            "AND fp.type_id = $ab_id[0][0] ".
            "AND a.type_id = $as_id[0][0] ".
            "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
    }
}

sub do_update_date {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @dt_id = $self->get_cv_term('date');
    my @feature_id = $self->get_feature_id($gene_id);

    if(!$self->row_exists('featureprop', 'value', 'type_id', $feature_id[0][0], $dt_id[0][0])) {
	$self->do_insert_date($gene_id, $db);
    }
    else {
	my $query = "UPDATE $db.featureprop fp, $db.feature a, $db.feature t, $db.featureloc fl SET ".
	    "fp.value = getdate() ".  ### update date
	    "WHERE t.uniquename = '$gene_id' ".
	    "AND t.feature_id = fl.feature_id ".
	    "AND fl.srcfeature_id = a.feature_id ".
	    "AND t.feature_id = fp.feature_id ".
	    "AND fp.type_id = $dt_id[0][0] ".
	    "AND a.type_id = $as_id[0][0] ".
	    "AND t.type_id = $tr_id[0][0] ";
	
	$self->_set_values($query);
    }
}

sub do_delete_comment {
    my ($self, $gene_id, $comment, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @co_id = $self->get_cv_term('comment', 'annotation_attributes.ontology');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $co_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_public_comment {
    my ($self, $gene_id, $public_comment, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @pc_id = $self->get_cv_term('public_comment');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $pc_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_gene_product_name {
    my ($self, $gene_id, $gene_product_name, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @gp_id = $self->get_cv_term('gene_product_name');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $gp_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_gene_symbol {
    my ($self, $gene_id, $gene_symbol, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @gs_id = $self->get_cv_term('gene_symbol');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $gs_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_GO_id {
    my ($self, $gene_id, $GO_id, $assigned_by_exclude, $db, $assigned_by) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @dt_id = $self->get_cv_term('date');
    my @ab_id = $self->get_cv_term('assignby');

    my $query = "SELECT fc.feature_cvterm_id ".
	        "FROM feature t, feature_cvterm fc, cvterm cvt, cv cv, dbxref d ".
		"WHERE t.uniquename = '$gene_id' ".
		"AND t.feature_id = fc.feature_id ".
		"AND fc.cvterm_id = cvt.cvterm_id ".
		"AND cvt.cv_id = cv.cv_id ".
		"AND cv.name IN ('process', 'function', 'component', 'biological_process', 'molecular_function', 'cellular_component', 'GO') ".
		"AND cvt.dbxref_id = d.dbxref_id ".
		"AND d.accession = '$GO_id' ";

    my $res = $self->_get_results_ref($query);

    #
    # Delete the rows from feature_cvtermprop (must be done first)
    # This will delete assignby, date, etc.
    my $query2 = "DELETE FROM feature_cvtermprop ".
	         "WHERE feature_cvterm_id = $res->[0][0] ";
    $self->_set_values($query2);

    #
    # Delete the rows from feature_cvterm
    # This will delete the relationship between GO id and transcript
    my $query3 = "DELETE FROM feature_cvterm ".
	         "WHERE feature_cvterm_id = $res->[0][0] ";
    $self->_set_values($query3);
}

sub do_delete_GO_evidence {
    my ($self, $gene_id, $GO_id, $assigned_by_exclude, $db, $assigned_by) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @tr_id = $self->get_cv_term('transcript');

    my $query = "DELETE fcp ".
	        "FROM dbxref d, cvterm c, feature t, feature_cvterm fc, cv cv, feature_cvtermprop fcp, cvtermsynonym cs ".
		"WHERE d.accession = '$GO_id' ".
		"AND t.uniquename = '$gene_id' ".
		"AND t.feature_id = fc.feature_id ".
		"AND fc.cvterm_id = c.cvterm_id ".
		"AND c.cv_id = cv.cv_id ".
		"AND cv.name IN ('process', 'function', 'component', 'biological_process', 'molecular_function', 'cellular_component', 'GO') ".
		"AND c.dbxref_id = d.dbxref_id ".
		"AND fc.feature_cvterm_id = fcp.feature_cvterm_id ".
		"AND fcp.type_id = cs.cvterm_id ".
		"AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_5prime_partial {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @fp_id = $self->get_cv_term('five_prime_partial');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $fp_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_3prime_partial {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @tp_id = $self->get_cv_term('three_prime_partial');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $tp_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_pseudogene_toggle {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @pg_id = $self->get_cv_term('is_pseudogene');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $pg_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_curated_structure {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @gs_id = $self->get_cv_term('gene_structure_curated');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $gs_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_curated_annotation {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @ga_id = $self->get_cv_term('gene_annotation_curated');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $ga_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub do_delete_signalP_curation {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @sp_id = $self->get_cv_term('signalp_curated');

    my $query = "DELETE fp ".
            "FROM $db..featureprop fp, $db..feature a, $db..feature t, $db..featureloc fl ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fp.feature_id ".
        "AND fp.type_id = $sp_id[0][0] ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ";

    $self->_set_values($query);
}

sub get_db_to_gene_features {
    my ($self, $db, $feat_type, $seq_id) = @_;
    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');
    my @ta_id = $self->get_cv_term('tRNA');
    my @rr_id = $self->get_cv_term('rRNA');
    my @nc_id = $self->get_cv_term('ncRNA');
    my @sn_id = $self->get_cv_term('snoRNA');
    my @tm_id = $self->get_cv_term('tmRNA');
    my @rz_id = $self->get_cv_term('ribozyme');
    my @rs_id = $self->get_cv_term('riboswitch');
								 
    my $query = "SELECT DISTINCT f.uniquename, a.uniquename, 'asmbl_name', fl.fmin, fl.fmax, ".
            "fl.strand, 'feature_name', cv.name, count(f.uniquename) ".
            "FROM cvterm cv, feature f, featureloc fl, feature a, organism o ".
        "WHERE f.type_id = cv.cvterm_id ".
        "AND f.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND f.organism_id = o.organism_id ".
        "AND o.common_name != 'not known' ".
        "AND f.is_obsolete = 0 ".
        "AND a.type_id = $as_id[0][0] ";

	if ((defined $seq_id) && (length($seq_id))){
		$query .= "AND a.uniquename = '$seq_id' "
	}

	$query .=	"AND f.type_id IN ($tr_id[0][0], $ta_id[0][0], $rr_id[0][0], $nc_id[0][0], $sn_id[0][0], $tm_id[0][0], $rz_id[0][0], $rs_id[0][0]) ".
		"GROUP BY cv.name, f.uniquename, a.uniquename, fl.fmin, fl.fmax, fl.strand, f.type_id, ".
		"cv.cvterm_id, f.feature_id, fl.feature_id, fl.srcfeature_id, a.feature_id, a.type_id ";

    return $self->_get_results_ref($query);
}

sub get_db_to_roles {
    my($self, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');

    my $query = "SELECT t.uniquename, d.accession ".
		        "FROM feature a, feature t, feature_cvterm fc, cvterm_dbxref cd, db, cvterm c, featureloc fl, organism o, dbxref d ".
				"WHERE t.feature_id = fl.feature_id ".
				"AND fl.srcfeature_id = a.feature_id ".
				"AND t.feature_id = fc.feature_id ".
				"AND fc.cvterm_id = c.cvterm_id ".
				"AND c.cvterm_id = cd.cvterm_id ".
				"AND cd.dbxref_id = d.dbxref_id ".
				"AND d.db_id = db.db_id ".
				"AND db.name = 'TIGR_role' ".
				"AND a.type_id = $as_id[0][0] ".
				"AND t.type_id = $tr_id[0][0] ".
				"AND t.is_obsolete = 0 ".
				"AND t.organism_id = o.organism_id ".
				"AND o.common_name != 'not known' ";

    return $self->_get_results_ref($query);
}

sub get_seq_id_to_description {
    my ($self, $seq_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @chr_cv_id = $self->get_cv_term('chromosome');

    my $query = "SELECT DISTINCT 'TEMP1', 'TEMP2', 'TEMP3', 'TEMP4', 'TEMP5', 'TEMP6', f1.seqlen, 'TEMP7', 'TEMP8', 'TEMP9', f1.timelastmodified, fp.value, 'TEMP11', 'TEMP12' ".
            "FROM $db..cvterm c, $db..featureprop fp, $db..feature f1, $db..organism o, $db..dbxref d ".
        "WHERE c.cvterm_id = $chr_cv_id[0][0] ".
        "AND c.cvterm_id = fp.type_id ".
        "AND fp.feature_id = f1.feature_id ".
        "AND f1.organism_id = o.organism_id ".
        "AND o.species = 'brucei' ".
        "AND f1.name != NULL ".
        "AND f1.dbxref_id = d.dbxref_id ".
        "AND f1.uniquename = ? ".
        "ORDER BY fp.value ";

    return $self->_get_results_ref($query, $seq_id);
}

sub get_seq_id_to_roles {
    my($self, $seq_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');

    my $query = "SELECT DISTINCT t.uniquename, d.accession, e.mainrole, e.sub1role, e.sub2role, d2.accession ".
            "FROM $db..cvterm c, $db..feature t, $db..feature_cvterm fc, $db..cvterm_dbxref cd, ".
        "$db..dbxref d, $db..db, egad..roles e, $db..dbxref d2, $db..featureloc fl, $db..feature a ".
        "WHERE t.feature_id = fc.feature_id ".
        "AND fc.cvterm_id = c.cvterm_id ".
        "AND c.cvterm_id = cd.cvterm_id ".
        "AND cd.dbxref_id = d.dbxref_id ".
        "AND d.db_id = db.db_id ".
        "AND db.name = 'TIGR_role' ".
        "AND t.dbxref_id = d2.dbxref_id ".
        "AND d.accession = e.role_id ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ".
        "AND a.uniquename = '$seq_id' ";

    return $self->_get_results_ref($query);
}

sub get_gene_id_to_roles {
    my ($self, $gene_id, $db) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;
    my @as_id = $self->get_cv_term('assembly');
    my @tr_id = $self->get_cv_term('transcript');

    my $query = "SELECT d.accession ".
            "FROM feature a, feature t, featureloc fl, feature_cvterm fc, cvterm_dbxref cd, ".
        "dbxref d, db db, cvterm c, cv cv, organism o ".
        "WHERE t.uniquename = '$gene_id' ".
        "AND t.feature_id = fl.feature_id ".
        "AND fl.srcfeature_id = a.feature_id ".
        "AND t.feature_id = fc.feature_id ".
        "AND fc.cvterm_id = c.cvterm_id ".
        "AND c.cv_id = cv.cv_id ".
        "AND cv.name = 'TIGR_role' ".
        "AND c.cvterm_id = cd.cvterm_id ".
        "AND cd.dbxref_id = d.dbxref_id ".
        "AND a.type_id = $as_id[0][0] ".
        "AND t.type_id = $tr_id[0][0] ".
        "AND t.organism_id = o.organism_id ".
        "AND o.common_name != 'not known' ".
        "AND d.db_id = db.db_id ".
        "AND db.name = 'TIGR_role' ";

    if($self->{_seq_id}) {
		$query .= "AND a.uniquename = '$self->{_seq_id}' ";
    }

	#print $query."<br/>";

    return $self->_get_results_ref($query);
}

sub get_role_id_to_categories {
    my($self, $id, $main) = @_;

    $self->{_logger}->debug("Args: " . join(',',splice(@_,1))) if $self->{_logger}->is_debug;

	my $query = "SELECT d2.accession, d1.accession ".
                "FROM db db1, cvterm c, cvterm_dbxref cd1, db db2, cvterm_dbxref cd2, dbxref d2, ".
				"dbxref d1 ".
				"WHERE d1.db_id = db1.db_id ".
				"AND db1.name = 'TIGR_role' ".
				"AND d1.dbxref_id = cd1.dbxref_id ".
				"AND cd1.cvterm_id = c.cvterm_id ".
				"AND c.cvterm_id = cd2.cvterm_id ".
				"AND cd2.dbxref_id = d2.dbxref_id ".
				"AND d2.db_id = db2.db_id ".
				"AND db2.name = 'TIGR_roles_order' ".
				"ORDER BY d2.accession ";				

    return $self->_get_results_ref($query);
}

###################################

1;
