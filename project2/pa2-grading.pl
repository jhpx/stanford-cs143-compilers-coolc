#!/usr/bin/perl -w

use strict;

use FileHandle;
use Getopt::Long;

my @check_files = ( "cool.y", "cool.cup" );
my $grading_dir = "./grading";
my $grading_cmd = "./143publicgrading PA3";
my $just_unpack;
my $just_run;
my $verbose;
my $skip_check;

sub usage {
    print "Usage: $0 [options]\n";
    print "    Options: -dir <path>  - specifies where to unpack/run\n";
    print "                            grading scripts [default = \"$grading_dir\"]\n";
    print "             -cmd <path>  - specifies what command to run for grading\n";
    print "                            [default = \"$grading_cmd\"]\n";
    print "             -x           - unpack script and test cases, but do not run\n";
    print "             -r           - don't unpack, just run existing script\n";
    print "             -v           - enable verbose output\n";
    return "\n";
}

die usage()
    unless(GetOptions("dir=s" => \$grading_dir,
		      "cmd=s" => \$grading_cmd,
		      "x" => \$just_unpack,
		      "r" => \$just_run,
		      "v" => \$verbose,
		      "skip" => \$skip_check,
		      "check=s" => \@check_files,
		      "help" => sub { usage(); exit 0; }));

unless($skip_check) {
    print "Checking that you appear to be in the assignment directory...\n"
	if($verbose);
    my(@found) = grep({ -r $_ } @check_files);
    unless(@found) {
	die "$0: could not find any of the following files - are you running\n  this from the assignment directory?\n    " . join("\n    ", @check_files) . "\n";
    }
}

print "Creating grading directory '$grading_dir' if necessary...\n"
    if($verbose);
unless((-d $grading_dir) or
       mkdir($grading_dir)) {
    die "$0: '$grading_dir' doesn't appear to be a directory and can't be created: $!";
}

print "Changing to grading directory '$grading_dir'...\n"
    if($verbose);
unless(chdir($grading_dir)) {
    die "$0: can't change directory to '$grading_dir'...\n";
}

unless($just_run) {
    print "Unpacking grading script and test cases...\n"
	if($verbose);

    my $tar_options = $verbose ? "-zxvf" : "-zxf";
    my $fh = new FileHandle("| tar $tar_options -") ||
	die "$0: couldn't run uudecode or tar: $!\n";

    # skip the first line
    my $dummy = <DATA>;
    die unless($dummy =~ /^begin /);
    binmode($fh);
    while(defined(my $line = <DATA>)) {
	$line =~ s/\s+$//;
	last if($line =~ /^end$/);
	my $unpacked = unpack('u', $line);	
	next unless(defined($unpacked));
	print $fh $unpacked;
    }
    $fh->close;
}

unless($just_unpack) {
    print "Running command: $grading_cmd\n"
	if($verbose);

    system($grading_cmd);
}


__DATA__
begin 644 /dev/stdout
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
DYQG<&9#T*1F92?JLSX%2$.IS( T:-&CXYIO_#]^ N6, < , 
 
end
