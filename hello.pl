#!/usr/bin/perl
use strict;
use warnings;
use File::Find;


use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

# Traverse desired filesystems
File::Find::find(\&wanted, '.');
exit;


sub wanted
{
  my $file = $_;
    -d _  && $file=~m/(26|84|28|88){1}\d{4}/ && print("$name\n");
}
