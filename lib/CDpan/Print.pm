#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-10-09

package CDpan::Print;

use strict;
use warnings;

use File::Spec::Functions qw /:ALL/;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

require Exporter;
our @ISA = qw \ Exporter \;
our @EXPORT = qw \ PrintExitMessage PrintWarnMessage PrintErrorMessage PrintStartMessage PrintEndMessage PrintProcessMessage PrintMessage PrintfMessage\;
our %EXPORT_TAGS = (
     PRINT => [ qw \ PrintExitMessage PrintWarnMessage PrintErrorMessage PrintStartMessage PrintEndMessage PrintProcessMessage PrintMessage PrintfMessage\ ],
     NONE => []);

sub PrintExitMessage {
    my $print_message = shift;

    print STDERR "$print_message\n";
    print STDERR "\n";
    print STDERR "For more information, try \'CDpan --help\'\n";

    exit(-1);
}

sub PrintWarnMessage {
    my $print_message = shift;

    print STDERR BOLD MAGENTA "Warning: ";
    print STDERR "$print_message\n";

    print $main::LOG "Warning: ";
    print $main::LOG "$print_message\n";

    return 1;
}

sub PrintErrorMessage {
    my $print_message = shift;
    my $is_die = shift // 1;

    print STDERR "\n";
    print STDERR BOLD RED "Error: ";
    print STDERR "$print_message\n";
    print STDERR "\n";

    print $main::LOG "\n";
    print $main::LOG "Error: ";
    print $main::LOG "$print_message\n";
    print $main::LOG "\n";

    exit(255) if $is_die;

    return 1;
}

sub PrintStartMessage {
    my $print_message = shift;

    print STDERR "--------------------------------------------------------------------------------\n";
    print STDERR "\n";
    print STDERR "$print_message\n";
    print STDERR "\n";

    print $main::LOG "--------------------------------------------------------------------------------\n";
    print $main::LOG "\n";
    print $main::LOG "$print_message\n";
    print $main::LOG "\n";

    return 1;
}

sub PrintEndMessage {
    my $print_message = shift;

    print STDERR "\n";
    print STDERR "$print_message\n";
    print STDERR "\n";

    print $main::LOG "\n";
    print $main::LOG "$print_message\n";
    print $main::LOG "\n";

    return 1;
}

sub PrintProcessMessage {
    my @print_message = split /%%/, shift;
    my @print_files = @_;

    print STDERR "    ";
    print $main::LOG "    ";

    foreach (@print_message) {
        print STDERR $_;
        print $main::LOG $_;

        last unless @print_files;

        my $file = shift @print_files;

        if ( ref $file ){
            foreach my $file_sub (@{$file}){
                ( my $file_name, my $idv_dir_name ) = reverse splitdir($file_sub);
                print STDERR "$idv_dir_name/$file_name ";
                print $main::LOG "$idv_dir_name/$file_name ";
            }
        }
        else {
            ( my $file_name, my $idv_dir_name ) = reverse splitdir($file);
            print STDERR "$idv_dir_name/$file_name";
            print $main::LOG "$idv_dir_name/$file_name";
        }
    }

    print STDERR "\n";
    print $main::LOG "\n";

    return 1;
}

sub PrintMessage {
    my $print_message = shift;

    print STDERR $print_message;
    print $main::LOG $print_message;

    return 1;
}

sub PrintfMessage {

    printf STDERR @_;
    printf $main::LOG @_;

    return 1;
}


1;

__END__
