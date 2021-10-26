#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-07-21

package CDpan::Module::Soot;

use strict;
use warnings;

use Bio::SeqIO;
use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;

use CDpan::Print qw / :PRINT /;

sub Soot {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'soot', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "soot" }){
        unless ( -e "${input_file_prefix}.filtered.mmseqs_rep_seq.fasta"){
            PrintErrorMessage("The input file ${input_file_prefix}.filtered.mmseqs_rep_seq.fasta does not exist, whether the input direction is the output direction of Module vot");
        }
    }

    # Read the software path
    my $nucmer = $par->val('TOOLS', 'nucmer');

    my $thread = $par->val('CDPAN', 'thread');

    my $ref = $par->val('DATA', 'ref');

    my $maxgap     = $par->val('SOOT', 'maxgap');
    my $mincluster = $par->val('SOOT', 'mincluster');
    my $minmatch   = $par->val('SOOT', 'minmatch');

    my $cmd_nucmer = "$nucmer " .
                     "-p ${output_file_prefix}.filtered.mmseqs " .
                     "$ref " .
                     "${input_file_prefix}.filtered.mmseqs_rep_seq.fasta " .
                     "-g $maxgap " .
                     "-c $mincluster " .
                     "-l $minmatch " .
                     "-t $thread";
    # print "Start use cmd: \'$cmd_nucmer\'.\n";
    PrintProcessMessage("Remove the contigs which could align to the reference genome, the results were written into %%", "${output_file_prefix}.filtered.mmseqs.delta");
    system $cmd_nucmer
        and PrintErrorMessage("Command \'$cmd_nucmer\' failed to run normally: $?");

    my $show_coords = $par->val('TOOLS', 'show-coords');

    my $cmd_show_coords = "$show_coords " .
                          "-rcl " .
                          "${output_file_prefix}.filtered.mmseqs.delta " .
                          "> ${output_file_prefix}.filtered.mmseqs.delta.coords";
    # print "Start use cmd: \'$cmd_show_coords\'.\n";
    PrintProcessMessage("show coords of alignments to %%", "${output_file_prefix}.filtered.mmseqs.delta.coords");
    system $cmd_show_coords
        and PrintErrorMessage("Command \'$cmd_show_coords\' failed to run normally: $?");

    PrintProcessMessage("precise delete to %%", "${output_file_prefix}.filtered.mmseqs.final.fa");
    if ( -s "${output_file_prefix}.filtered.mmseqs.delta.coords" ) {
        my $cmd_repeat = "tail -n +6 ${output_file_prefix}.filtered.mmseqs.delta.coords " .
                        "| awk \'{print \$19}\' - " .
                        "| sort -u - " .
                        "> ${output_file_prefix}.repeat.names";
        # print "Start use cmd: \'$cmd_repeat\'.\n";
        system $cmd_repeat
            and PrintErrorMessage("Command \'$cmd_repeat\' failed to run normally: $?");

        open my $REPEAT, "<", "${output_file_prefix}.repeat.names"
            or PrintErrorMessage("Couldn't open file ${output_file_prefix}.repeat.names: $!");
        my %id_repeat = map {chomp; $_, 1} (<$REPEAT>);

        open my $INPUT, "<", "${input_file_prefix}.filtered.mmseqs_rep_seq.fasta"
            or PrintErrorMessage("Couldn't open file ${input_file_prefix}.filtered.mmseqs_rep_seq.fasta: $!");
        open my $OUTPUT, ">", "${output_file_prefix}.filtered.mmseqs.final.fa"
            or PrintErrorMessage("Couldn't create file ${output_file_prefix}.filtered.mmseqs.final.fa: $!");

        my $seq_input = Bio::SeqIO->new(-fh     => $INPUT,
                                        -format => 'Fasta');

        while (my $seq = $seq_input->next_seq) {
            my $seq_id = $seq->id;
            unless ( $id_repeat{ $seq_id } ) {
                print $OUTPUT ">$seq_id \n" . $seq->seq . "\n";
            }
        }
    }
    else{
        copy("${input_file_prefix}.filtered.mmseqs_rep_seq.fasta", "${output_file_prefix}.filtered.mmseqs.final.fa")
             or PrintErrorMessage("Copy file \'${input_file_prefix}.filtered.mmseqs_rep_seq.fasta\' to \'${output_file_prefix}.filtered.mmseqs.final.fa\' failed: $!");
    }

    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        unlink "${output_file_prefix}.repeat.names" or PrintErrorMessage("Cannot delete file: ${output_file_prefix}.repeat.names: $!");
    }

    if ( $par->val('CDPAN', 'output_level') == 0 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}.filtered.mmseqs.final.fa"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    return 1;
}

1;

__END__
