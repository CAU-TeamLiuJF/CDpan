#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-08-11

package CDpan::Module::Merge;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;

use CDpan::Print qw / :PRINT /;

sub Merge {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'merge');

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "merge" }){
        unless ( -e "${input_file_prefix}.filtered.mmseqs.final.fa"){
            PrintErrorMessage("The input file ${input_file_prefix}.filtered.mmseqs.final.fa does not exist, whether the input direction is the output direction of Module soot");
        }
    }

    PrintProcessMessage("Merge the new DNA sequences from all individuals and remove the redundancy contigs, the results were written into %%", "$output_dir/merge.fasta");
    open my $OUTPUT , ">>", "$output_dir/merge.fasta"
        or PrintErrorMessage("Couldn't create output file $output_dir/all.fasta: $!.");

    my $merge_index = $par->val('MERGE', 'merge_index') // 0;

    open my $INPUT, "<", "${input_file_prefix}.filtered.mmseqs.final.fa"
        or PrintErrorMessage("Could not open individual file ${input_file_prefix}.filtered.mmseqs.final.fa: $!.");

    while (<$INPUT>) {
        if ( m/^>/ ){
            $merge_index += 1;
            print $OUTPUT ">dsp$merge_index\n";
        }else{
            print $OUTPUT $_;
        }
    }

    close $INPUT;
    close $OUTPUT;

    $par->newval('MERGE', 'merge_index', $merge_index);

    return 1;
}

1;

__END__
