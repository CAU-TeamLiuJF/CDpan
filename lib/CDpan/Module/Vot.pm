#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-07-21

package CDpan::Module::Vot;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;
use File::Path qw / rmtree /;

use CDpan::Print qw / :PRINT /;

sub Vot {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'vot', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "vot" }){
        unless ( -e "${input_file_prefix}.filtered.fa"){
            PrintErrorMessage("The input file ${input_file_prefix}.filtered.fa does not exist, whether the input direction is the output direction of Module mope");
        }
    }

    # Read the software path
    my $mmseqs = $par->val('TOOLS', 'mmseqs');

    my $thread = $par->val('CDPAN', 'thread');

    my $cov_mode     = $par->val('VOT', 'cov-mode');
    my $coverage     = $par->val('VOT', 'coverage');
    my $min_seq_id   = $par->val('VOT', 'min-seq-id');
    my $cluster_mode = $par->val('VOT', 'cluster-mode');

    my $cmd_mmseqs = "$mmseqs easy-linclust " .
                     "${input_file_prefix}.filtered.fa " .
                     "${output_file_prefix}.filtered.mmseqs " .
                     "$output_dir/mmseqs_tmp " .
                     "--threads $thread " .
                     "--cov-mode $cov_mode " .
                     "-c $coverage " .
                     "--min-seq-id $min_seq_id " .
                     "--cluster-mode $cluster_mode " .
                     "> ${output_file_prefix}.filtered.mmseqs.log";
    # print "Start use cmd: \'$cmd_mmseqs\'.\n";
    PrintProcessMessage("Remove the repetitive contigs and write the results into %%", "${output_file_prefix}.filtered.mmseqs_rep_seq.fasta");
    system $cmd_mmseqs
        and PrintErrorMessage("Command \'$cmd_mmseqs\' failed to run normally: $?");

    if ( -e "$output_dir/mmseqs_tmp" ){
        rmtree "$output_dir/mmseqs_tmp" or PrintErrorMessage("Cannot delete direction $output_dir/mmseqs_tmp: $!");
    }

    if ( $par->val('CDPAN', 'output_level') == 0 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}.filtered.mmseqs_rep_seq.fasta"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    return 1;
}

1;

__END__
