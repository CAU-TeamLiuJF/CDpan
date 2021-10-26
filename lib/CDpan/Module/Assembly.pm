#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-04-07

package CDpan::Module::Assembly;

use strict;
use warnings;

use Config::IniFiles;
use File::Copy;
use File::Spec::Functions qw /:ALL/;
use File::Path qw / rmtree /;

use CDpan::Print qw / :PRINT /;

sub Assembly {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'assembly', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "assembly" }){
        my @input_file_suffixs = qw \ .mateUnmapped_R1.fq
                                      .mateUnmapped_R2.fq
                                      .R1_mateMapped.fq
                                      .R2_mateMapped.fq \ ;
        foreach my $input_file_suffix (@input_file_suffixs){
            unless ( -e "${input_file_prefix}${input_file_suffix}"){
                PrintErrorMessage("The input file ${input_file_prefix}${input_file_suffix} does not exist, whether the input direction is the output direction of Module extract");
            }
        }
    }

    my $thread  = $par->val('CDPAN', 'thread');
    my $fragment_mean  = $par->val('ASSEMBLY', 'fragment-mean');
    my $fragment_stdev = $par->val('ASSEMBLY', 'fragment-stdev');
    my $jf_size = $par->val('ASSEMBLY', 'JF_SIZE');

    my $config = "" .
    "DATA\n" .
    "PE= pe $fragment_mean $fragment_stdev ${input_file_prefix}.mateUnmapped_R1.fq ${input_file_prefix}.mateUnmapped_R2.fq\n" .
    "PE= s1 $fragment_mean $fragment_stdev ${input_file_prefix}.R1_mateMapped.fq\n" .
    "PE= s2 $fragment_mean $fragment_stdev ${input_file_prefix}.R2_mateMapped.fq\n" .
    "END\n" .
    "\n" .
    "PARAMETERS\n" .
    "GRAPH_KMER_SIZE = auto\n" .
    "USE_LINKING_MATES = 1\n" .
    "KMER_COUNT_THRESHOLD = 1\n" .
    "NUM_THREADS = $thread\n" .
    "JF_SIZE=$jf_size\n" .
    "DO_HOMOPOLYMER_TRIM=0\n" .
    "END\n";

    open CONFIG, '>', "${output_file_prefix}.masurca_config.txt"
        or PrintErrorMessage("Couldn't create ${output_file_prefix}.masurca_config.txt: $!");
    print CONFIG $config;
    close CONFIG;

    chdir $output_dir;

    my $masurca = $par->val('TOOLS', 'masurca');

    my $cmd_masurca = "$masurca ${output_file_prefix}.masurca_config.txt > ${output_file_prefix}.masurca_config.log";
    # print "Start use cmd: \'$cmd_masurca\'.\n";
    PrintProcessMessage('assembled to %%', "${output_file_prefix}.final.genome.scf.fasta");
    system $cmd_masurca
        and PrintErrorMessage("Command \'$cmd_masurca\' failed to run normally: $?");

    mkdir "$output_dir/assemble" or PrintErrorMessage("Couldn't create $output_dir/assemble: $!");
    chdir "$output_dir/assemble";
    system "../assemble.sh > ../assemble.log"
        and PrintErrorMessage("Command ../assemble.sh: $?");
    if ( -e "./CA/final.genome.scf.fasta"){
        move("./CA/final.genome.scf.fasta", "${output_file_prefix}.final.genome.scf.fasta")
            or PrintErrorMessage("Couldn't move file: /CA/final.genome.scf.fasta: $!");
    }
    else{
        PrintWarnMessage("Couldn't find file: /CA/final.genome.scf.fasta: $!");
    }

    chdir $output_dir;

    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        rmtree "$output_dir/assemble" or PrintErrorMessage("Cannot delete direction $output_dir/assemble: $!");
    }

    if ( $par->val('CDPAN', 'output_level') < 1 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}.final.genome.scf.fasta"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    chdir $main::cwd or PrintErrorMessage("Cannot chdir to $main::cwd: $!");

    return 1;
}


1;

__END__
