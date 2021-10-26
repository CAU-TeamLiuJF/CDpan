#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-08-11

package CDpan::Module::Location;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;
use File::Copy qw / copy move /;
use File::Path qw / mkpath rmtree /;
use List::Util qw / max min /;

use CDpan::Print qw / :PRINT /;

sub PreLocation {
    (my $par) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'), 'pre_location');
    mkdir $output_dir or PrintErrorMessage("Cannot create work direction $output_dir: $!");

    my $input_file = catfile($par->val('CDPAN', 'input_dir'), 'merge.fasta');
    if ($main::modules{ "location" }){
        unless ( -e $input_file){
            PrintErrorMessage("The input file $input_file does not exist, whether the input direction is the output direction of Module merge");
        }
    }

    copy $input_file, "$output_dir/merge.fasta"
        or PrintErrorMessage("Cannot copy file $input_file to $output_dir/merge.fasta: $!");

    # Read the software path
    my $repeat_masker = $par->val('TOOLS', 'RepeatMasker');

    my $thread  = $par->val('CDPAN',    'thread');
    my $species = $par->val('LOCATION', 'species');

    my $cmd_repeat_masker = "$repeat_masker " .
                            "-parallel $thread " .
                            "-nolow " .
                            "-species $species " .
                            "$output_dir/merge.fasta " .
                            "> $output_dir/repeat_masker.log";
    # print "Start use cmd: \'$cmd_repeat_masker\'.\n";
    PrintProcessMessage('screen sequence to %%*', "$output_dir/merge.fasta");
    system $cmd_repeat_masker
        and PrintErrorMessage("Command \'$cmd_repeat_masker\' failed to run normally: $?");

    # Read the software path
    my $samtools = $par->val('TOOLS', 'samtools');

    my $cmd_samtools = "$samtools " .
                       "faidx " .
                       "$output_dir/merge.fasta";
    # print "Start use cmd: \'$cmd_samtools\'.\n";
    PrintProcessMessage('queries regions to %%', "$output_dir/merge.fasta.fai");
    system $cmd_samtools
        and PrintErrorMessage("Command \'$cmd_samtools\' failed to run normally: $?");

    system "awk '{print \$1,\$2}' $output_dir/merge.fasta.fai > $output_dir/merge.fasta.length";

    # Read the software path
    my $bowtie2_build = $par->val('TOOLS', 'bowtie2-build');
    my $cmd_bowtie2_build = "$bowtie2_build " .
                            "$output_dir/merge.fasta.masked " .
                            "$output_dir/index " .
                            "> $output_dir/bowtie2_build1.log " .
                            "2> $output_dir/bowtie2_build2.log";
    # print "Start use cmd: \'$cmd_bowtie2_build\'.\n";
    PrintProcessMessage('build index to %%*', "$output_dir/index");
    system $cmd_bowtie2_build
        and PrintErrorMessage("Command \'$cmd_bowtie2_build\' failed to run normally: $?");

    $par->newval('RESULT', 'pre_location', $output_dir);

    return 1;
}

sub RemovePreLocation {
    (my $par) = @_;

    my $pre_location_dir = catdir($par->val('CDPAN', 'work_dir'), 'pre_location');

    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        rmtree $pre_location_dir or PrintErrorMessage("Cannot delete direction $pre_location_dir: $!");
    }
    elsif ($main::modules{ "location" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'pre_location');
        move $pre_location_dir, $output_dir or PrintErrorMessage("Couln't move $pre_location_dir to $output_dir: $!");
    }elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }) {
        $par->newval('RESULT', 'pre_location', $pre_location_dir);
    }

    return 1;
}

sub Location {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'location', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $pre_location_dir = $par->val('RESULT', 'pre_location');

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "location" }){
        unless ( -e "${input_file_prefix}.singleUnmapped_R2.fq"){
            PrintErrorMessage("The input file ${input_file_prefix}.singleUnmapped_R2.fq does not exist, whether the input direction is the output direction of Module vot");
        }
    }

    # Read the software path
    my $bowtie2 = $par->val('TOOLS',  'bowtie2');
    my $thread  = $par->val('CDPAN',  'thread');

    my $cmd_align = "$bowtie2 " .
                    "-x $pre_location_dir/index " .
                    "-U ${input_file_prefix}.singleUnmapped_R2.fq,${input_file_prefix}.singleUnmapped_R2.fq " .
                    "-S ${output_file_prefix}.readContigAlignment.final.sam " .
                    "-p $thread " .
                    "2> ${output_file_prefix}.bowtie2.log";
    # print "Start use cmd: \'$cmd_align\'.\n";
    PrintProcessMessage('alignment:the results were writtein to %%', "${output_file_prefix}.readContigAlignment.final.sam");
    system $cmd_align
        and PrintErrorMessage("Command \'$cmd_align\' failed to run normally: $?");

    # Read the software path
    my $samtools = $par->val('TOOLS', 'samtools');
    my $bedtools = $par->val('TOOLS', 'bedtools');

    my $cmd_samtools1 = "$samtools view -@ $thread -h " .
                        "-F 256 ${output_file_prefix}.readContigAlignment.final.sam " .
                        "| $samtools sort - -n -O bam -@ $thread " .
                        "2> /dev/null " .
                        "| $bedtools bamtobed -i stdin " .
                        "| awk \'{OFS=\"\\t\"}{print \$4,\$1,\$6,\$2,\$3}\' " .
                        "| sort > ${output_file_prefix}.readContigAlignment.txt";
    # print "Start use cmd: \'$cmd_samtools1\'.\n";
    PrintProcessMessage('extract the alignment to %%', "${output_file_prefix}.readContigAlignment.txt");
    system $cmd_samtools1
        and PrintErrorMessage("Command \'$cmd_samtools1\' failed to run normally: $?");

    my $cmd_samtools2 = "$samtools view -@ $thread " .
                        "-H ${input_file_prefix}.Sus_11_1_Links.bam " .
                        "| cat - <(awk \'FNR==NR{main[\$1]=\$0;next} \$1 in main {print main[\$1]}\' " .
                                "<($samtools view -@ $thread ${input_file_prefix}.Sus_11_1_Links.bam) " .
                                "${output_file_prefix}.readContigAlignment.txt) " .
                        "| $samtools sort -n -O bam -@ $thread " .
                        "2> /dev/null " .
                        "| $bedtools bamtobed -i stdin " .
                        "| awk \'{OFS=\"\\t\"}{print \$4,\$1,\$6,\$2,\$3}\' " .
                        "| sed -e \'s/\\/[1-2]//g\' " .
                        "| sort > ${output_file_prefix}.matchedMates.txt";
    # print "Start use cmd: \'$cmd_samtools2\'.\n";
    PrintProcessMessage('extract the alignment results of hangning reads to %%', "${output_file_prefix}.matchedMates.txt");

    open my $TMP, '>', "${output_file_prefix}.tmp.sh";
    print $TMP $cmd_samtools2;
    close $TMP;

    system "bash ${output_file_prefix}.tmp.sh"
        and PrintErrorMessage("Command \'$cmd_samtools2\' failed to run normally: $?");

    unlink "${output_file_prefix}.tmp.sh";

    my $cmd_join = "join " .
                   "-j 1 " .
                   "${output_file_prefix}.readContigAlignment.txt " .
                   "${output_file_prefix}.matchedMates.txt " .
                   "> ${output_file_prefix}.mateLinks.txt";
    # print "Start use cmd: \'$cmd_join\'.\n";
    PrintProcessMessage('integrated the previous alignment results into %%', "${output_file_prefix}.mateLinks.txt");
    system $cmd_join
        and PrintErrorMessage("Command \'$cmd_join\' failed to run normally: $?");

    my $vot_dir = $par->val('RESULT', 'vot') // $par->val('LOCATION', 'vot_dir');
    my $vot_dir_prefix = catfile($vot_dir, $idv_name, $idv_name);
    my $minimap2 = $par->val('TOOLS', 'minimap2');

    my $cmd_minimap2 = "$minimap2 " .
                       "-x asm10 " .
                       "$pre_location_dir/merge.fasta " .
                       "${vot_dir_prefix}.filtered.mmseqs_rep_seq.fasta " .
                       "> ${output_file_prefix}.aln.paf " .
                       "2> ${output_file_prefix}.aln.paf.log";
    # print "Start use cmd: \'$cmd_minimap2\'.\n";
    PrintProcessMessage('the PAV identification of the new DNA sequences, the results were written into %%', "${output_file_prefix}.aln.paf");
    system $cmd_minimap2
        and PrintErrorMessage("Command \'$cmd_minimap2\' failed to run normally: $?");

    PrintProcessMessage('output location');
    mkdir "$output_dir/link_new"
        or PrintErrorMessage("Cannot create process folder '$output_dir/link_new': $!");
    chdir "$output_dir/link_new"
        or PrintErrorMessage("Cannot chdir to '$output_dir/link_new': $!");

	mkdir "./1";
	mkdir "./2";
	mkdir "./3";
	mkdir "./4";

    system ':> ./3.contig.name';
    system ':> ./3.contig.name.length';
    system ':> ./4.contig.name';
    system ':> ./4.contig.name.length';
    system ':> ./contig.name';

    system ':> ./1/1.name';
    system ':> ./1/2a.name';
    system ':> ./1/2bleft.name';
    system ':> ./1/2bright.name';
    system ':> ./1/3.name';
    system ':> ./1/4.name';
    system ':> ./1/5.name';

    # archive the contig name and length
    system "awk '{print \$1,\$2}' $pre_location_dir/merge.fasta.fai > ./contig.name"
        and PrintErrorMessage("Command failed to run normally: $?");

    open my $CONTIG, '<', "${output_file_prefix}.mateLinks.txt"
        or PrintErrorMessage("Cannot open file ${output_file_prefix}.mateLinks.txt: $!");

    my %contig;
    my $line = 0;
    while(<$CONTIG>) {
        chomp;
        my @contig_lines = split /\s+/, $_;
        $contig{$contig_lines[1]}{$line} = $_;
        $line++;
    }
    close $CONTIG;

    open my $INPUT, "<", "./contig.name"
        or PrintErrorMessage("Cannot open file '$output_dir/link_new/contig.name': $!");
    open my $OUTPUT1, ">", "./1/1.name"
        or PrintErrorMessage("Cannot create file '$output_dir/link_new/1/1.name': $!");
    open my $OUTPUT2, ">", "./1/2to4.name"
        or PrintErrorMessage("Cannot create file '$output_dir/link_new/1/2to4.name': $!");

    my @contig_2to4;
    while(<$INPUT>) {
        chomp;
        my @lines_links = split /\s+/, $_;
        my $have_contigs = 0;

        open my $LINK, ">", "./4/$lines_links[0].link"
            or PrintErrorMessage("Cannot create file '$output_dir/link_new/4/$lines_links[0].link': $!");

        if( exists $contig{$lines_links[0]} ) {
            foreach my $key (keys %{$contig{$lines_links[0]}}) {
                print $LINK "$contig{$lines_links[0]}{$key}\n";
            }
            $have_contigs = 1;
        }
        close $LINK;

        if($have_contigs) {
            print $OUTPUT2 "$_\n";
            push @contig_2to4, $lines_links[0];
        }else{
            print $OUTPUT1 "$_\n";
        }
    }

    close $INPUT;

    my @contig_3;
    foreach my $contig_2to4_em (@contig_2to4) {
        system "awk '{print \$6}' ./4/$contig_2to4_em.link | sort - | uniq -c - | sed 's/^[ ]*//' >./4/$contig_2to4_em.chr"
            and PrintErrorMessage("Command failed to run normally: $?");

        open my $CHR_FILE, '<', "./4/$contig_2to4_em.chr"
            or PrintErrorMessage("Cannot create file '$output_dir/link_new/4/$contig_2to4_em.chr': $!");
        my $chr_sum = 0;
        my @chr;
        my @chr_num;
        while(<$CHR_FILE>) {
            chomp;
            my @lines_chr = split /\s+/, $_;
            push @chr_num, $lines_chr[0];
            push @chr, $lines_chr[1];
            $chr_sum += $lines_chr[0];
        }
        close $CHR_FILE;

        while (@chr_num) {
            my $chr_num = shift @chr_num;
            my $chr = shift @chr;

            my $pr = $chr_num / $chr_sum;
            if ( $pr >= 0.95 ) {
                open my $CHR_OUT, '>>', "./3.contig.name"
                    or PrintErrorMessage("Cannot create file '$output_dir/link_new/3.contig.name': $!");
                print $CHR_OUT "$contig_2to4_em $chr\n";
                push @contig_3, $contig_2to4_em;
                close $CHR_OUT;

                move "./4/$contig_2to4_em.link", "./3/$contig_2to4_em.link"
                    or PrintErrorMessage("Cannot move file '$output_dir/link_new/4/$contig_2to4_em.link': $!");
                unlink "./4/$contig_2to4_em.chr";
                last;
            }
        }
        unlink "./4/$contig_2to4_em.chr" if ( -e "./4/$contig_2to4_em.chr" );
    }

    mkdir "./2/2a";
    mkpath "./2/2b/left";
    mkpath "./2/2b/right";

    foreach my $contig_3_em ( @contig_3 ) {
        system "sort -u ./3/$contig_3_em.link >./3/$contig_3_em.link.new"
            and PrintErrorMessage("Command failed to run normally: $?");
    }

    system "awk 'NR==FNR{a[\$1]=\$2;next}{print \$1,a[\$1],\$2}' ./contig.name ./3.contig.name >./3.contig.name.length"
            and PrintErrorMessage("Command failed to run normally: $?");

    open my $CONTIG_LENGTH, '<', "./3.contig.name.length"
        or PrintErrorMessage("Cannot open file '$output_dir/link_new/3.contig.name.length': $!");

    while (<$CONTIG_LENGTH>) {
        ( my $contig3_contig, my $contig3_length, my $contig3_chr ) = split /\s+/, $_;
        do3($contig3_contig, "./3/$contig3_contig.link.new", $contig3_length, $contig3_chr);
    }

    close $CONTIG_LENGTH;

    system 'for i in `ls ./4/`; do if [ -s ./4/$i ]; then echo $i | cut -d . -f1 >>./4.contig.name;fi; done'
        and PrintErrorMessage("Command failed to run normally: $?");

    system "awk 'NR==FNR{a[\$1]=\$2;next}{print \$1,a[\$1],\$2}' ./contig.name ./4.contig.name > ./4.contig.name.length"
            and PrintErrorMessage("Command failed to run normally: $?");

    open $CONTIG_LENGTH, '<', "./4.contig.name.length"
        or PrintErrorMessage("Cannot open file '$output_dir/link_new/4.contig.name.length': $!");

    while (<$CONTIG_LENGTH>) {
        ( my $contig4_contig, my $contig4_length ) = split /\s+/, $_;
        do4($contig4_contig, "./4/$contig4_contig.link", $contig4_length);
    }

    close $CONTIG_LENGTH;

    system 'for i in `ls ./4/`; do if [ -s ./4/$i ]; then echo $i | cut -d . -f1 >>./1/4.name;fi; done'
        and PrintErrorMessage("Command failed to run normally: $?");

    system 'for i in `ls ./3/`; do if [ -s ./3/$i ]; then echo $i | cut -d . -f1 >>./1/3.name;fi; done'
        and PrintErrorMessage("Command failed to run normally: $?");

    open my $CONTIG_NAME, '<', "./1/3.name"
        or PrintErrorMessage("Cannot open file '$output_dir/link_new/1/3.name': $!");

    while (<$CONTIG_NAME>) {
        chomp;
        system "awk '{print \$6}' ./3/$_.link | sort - | uniq -c - | sed 's/^[ ]*//' - | sort -nrk 1 - | head -n 1 - > ./3/$_.chr"
            and PrintErrorMessage("Command failed to run normally: $?");
        system "chrpart3=\$\(awk \'\{print \$2\}\' ./3/$_.chr\); printf \"$_ \$chrpart3\\n\" >> ./1/3.name.re"
            and PrintErrorMessage("Command failed to run normally: $?");
    }

    unlink "./1/2to4.name";

    system "awk 'NR==FNR{a[\$1]=\$2;next}{print \$1,a[\$1],\$2}' ./contig.name ./1/4.name > ./1/4.name.re"
        and PrintErrorMessage("Command failed to run normally: $?");

    system 'mv ./1/4.name.re ./1/4.name'
        and PrintErrorMessage("Command failed to run normally: $?");
    system 'mv ./1/3.name.re ./1/3.name'
        and PrintErrorMessage("Command failed to run normally: $?");

    system 'for i in `ls ./4/`; do if [ ! -s ./4/$i ]; then echo $i | cut -d . -f1 >>./1/5.name;fi; done'
        and PrintErrorMessage("Command failed to run normally: $?");

    system "rm -rf ./4";
    mkdir "./4";

    chdir $main::cwd or PrintErrorMessage("Cannot chdir to $main::cwd: $!");

    system "cp $output_dir/link_new/1/* $output_dir";

    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        rmtree "$output_dir/link_new" or PrintErrorMessage("Cannot delete direction $output_dir/link_new: $!");
        unlink "${output_file_prefix}.readContigAlignment.txt" or PrintErrorMessage("Cannot delete file: ${output_file_prefix}.readContigAlignment.txt: $!");
        unlink "${output_file_prefix}.readContigAlignment.final.sam" or PrintErrorMessage("Cannot delete file: ${output_file_prefix}.readContigAlignment.final.sam: $!");
    }

    if ( $par->val('CDPAN', 'output_level') == 0) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "$output_dir/1.name" and
                $_ ne "$output_dir/2a.name" and
                $_ ne "$output_dir/2bleft.name" and
                $_ ne "$output_dir/2bright.name" and
                $_ ne "$output_dir/3.name" and
                $_ ne "$output_dir/4.name" and
                $_ ne "$output_dir/5.name" and
                $_ ne "${output_file_prefix}.aln.paf"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    return 1;

    sub do3 {
        ( my $opt_n, my $opt_i, my $opt_l, my $opt_c) = @_;

        open IN,"<$opt_i";
        open OUT1,">$opt_i.left";
        open OUT2,">$opt_i.right";
        while(<IN>) {
            chomp $_;
            my @a = split /\s+/, $_;
            my $ed = $opt_l - 500;
            if( ($a[4] <= 500) && ($a[3] <= 500) && $a[5] eq $opt_c) {
                print OUT1 "$_\n"; ##output the left end results
            } elsif(($a[4] >= $ed) && ($a[3] >= $ed) && $a[5] eq $opt_c) {
                print OUT2 "$_\n"; ##output the right end results
            }
        }
        close IN;
        close OUT1;
        close OUT2;

        my $left = 0;
        my $right = 0;
        my %hash;  # chromosome alignment results

        # left end place
        foreach my $file_suffix ( qw \ left right\ ){
            if ( -s "$opt_i.$file_suffix" ) {
                open IN,"<$opt_i.$file_suffix";
                my @st;
                my @ed;
                while(<IN>) {
                    my @cc=split/\s+/,$_;
                    ($cc[7] , $cc[8]) = ($cc[8] , $cc[7]) if ( $cc[7] > $cc[8] );
                    push @st, $cc[7];
                    push @ed, $cc[8];
                }
                close IN;

                if( max( @ed ) - min( @st ) <= 2000 ) {
                    $left  = 1 if $file_suffix eq "left";   # left  ensure
                    $right = 1 if $file_suffix eq "right";  # right ensure
                    my $stmid = int(mid(@st));
                    my $edmid = int(mid(@ed));
                    $hash{$opt_n}{$file_suffix}="$opt_n $stmid $edmid";  ##left end on chromosome
                }
            }
        }

        open OUT1,">>./1/2bleft.name";
        open OUT2,">>./1/2bright.name";
        open OUT3,">>./1/2a.name";

        if($left==0 && $right==0) {
            unlink "$opt_i","$opt_i.right","$opt_i.left";
        }
        elsif($left != 0 && $right==0) {
            my @a=split/\s+/,$hash{$opt_n}{"left"};
            print OUT1 "$opt_n $opt_l $opt_c $a[1] $a[2]\n";
            system "mv ./3/$opt_n.link ./2/2b/left";
            unlink "$opt_i","$opt_i.right","$opt_i.left";
        }
        elsif($left == 0 && $right != 0) {
            my @a=split/\s+/,$hash{$opt_n}{"right"};
            print OUT2 "$opt_n $opt_l $opt_c $a[1] $a[2]\n";
            system"mv ./3/$opt_n.link ./2/2b/right";
            unlink "$opt_i","$opt_i.right","$opt_i.left";
        }
        elsif($left != 0 && $right != 0) {
            my @a=split/\s+/,$hash{$opt_n}{"left"};
            my @b=split/\s+/,$hash{$opt_n}{"right"};
            print OUT3 "$opt_n $opt_l $opt_c $a[1] $a[2] $b[1] $b[2]\n";
            system"mv ./3/$opt_n.link ./2/2a";
            unlink "$opt_i","$opt_i.right","$opt_i.left";
        }

        sub mid{
            my @list = sort{$a<=>$b} @_;
            my $count = @list;
            return undef if( $count == 0 );

            if( ($count%2) == 1 ){
                return $list[int(($count-1)/2)];
            } elsif ( ($count%2)==0 ) {
                return ($list[int(($count-1)/2)]+$list[int(($count)/2)])/2;
            }
        }

        return 1;
    }

    sub do4 {
        ( my $opt_n, my $opt_i, my $opt_l) = @_;

        open IN,"<$opt_i";
        open OUT1,">$opt_i.left";
        open OUT2,">$opt_i.right";
        while(<IN>) {
            chomp;
            my @a=split/\s+/,$_;
            my $ed=$opt_l-500;
            if(($a[4] <= 500) && ($a[3] <= 500)) {
                print OUT1 "$_\n"; # output the left end results
            } elsif(($a[4] >= $ed) && ($a[3] >= $ed)) {
                print OUT2 "$_\n"; ##output the right end results
            }
        }
        close IN;
        close OUT1;
        close OUT2;

        ##left end place
        PLACE:foreach my $file_suffix ( qw \ left right\ ){
            system"awk '{print \$6}' $opt_i.$file_suffix | sort - | uniq -c - | sed 's/^[ ]*//' > $opt_i.$file_suffix.chr";
            if ( -s "$opt_i.$file_suffix.chr") {
                open IN,"<$opt_i.$file_suffix.chr";
                my $sum=0;
                my @b;
                my @chr;
                while(<IN>) {
                    chomp;
                    my @a = split /\s+/, $_;
                    push @b, $a[0];
                    push @chr, $a[1];
                    $sum += $a[0];
                }
                close IN;
                foreach my $b_em ( @b ) {
                    if( $b_em/$sum >=0.95) {
                        move "$opt_i", "./3";
                        unlink "$opt_i.$file_suffix", "$opt_i.$file_suffix.chr";
                        last PLACE;
                    }
                }
            }
            unlink "$opt_i.$file_suffix", "$opt_i.$file_suffix.chr";
        }
        unlink "$opt_i.right" if ( -e "$opt_i.right" );

        return 1;
    }
}

sub Compare {
    (my $par) = @_;

    my $pre_location_dir = $par->val('RESULT', 'pre_location');
    my $location_dir = catdir($par->val('CDPAN', 'work_dir'), 'location');

    system "$main::FindBin::Bin/compare.py $pre_location_dir/merge.fasta.length $location_dir"
        and PrintErrorMessage("compare exited abnormally");

    return 1;
}

1;

__END__
