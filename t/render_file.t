#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 6;

use IO::File;
use URI::Escape ();
use File::Spec;
use File::Temp qw/ tempdir /;

my $file = IO::File->new;
# cache_dir
my $tempdir = tempdir(CLEANUP => 1);
# haml template
$file->open(File::Spec->catfile('t', 'render1.haml'), 'r') or die $!;
my $haml1_content = do { local $/; <$file> };
$file->close;
# create haml file for test
my $render_haml = File::Spec->catfile($tempdir, 'render.haml');
$file->open($render_haml, 'w') or die $!;
print $file $haml1_content;
$file->close;

my $haml = Text::Haml->new(
	path => $tempdir,
	cache_dir => $tempdir,
	cache => 1,
);

my $output = $haml->render_file('render.haml');
$file->open(File::Spec->catfile('t', 'render1.html'), 'r') or die $!;
my $expected1 = do { local $/; <$file> };
$file->close;
is($output, $expected1);

my $uri_escaped = URI::Escape::uri_escape($tempdir);
my $cache_dir = File::Spec->catdir($tempdir, $uri_escaped);
diag($cache_dir);
ok(-d $cache_dir);
my $cache_path = File::Spec->catfile($cache_dir, 'render.haml.pl');
ok(-f $cache_path);
cmp_ok(-s $cache_path, '>', 1);


# haml template
$file->open(File::Spec->catfile('t', 'render2.haml'), 'r') or die $!;
my $haml2_content = do { local $/; <$file> };
$file->close;
# overwrite haml file for test
$file->open($render_haml, 'w') or die $!;
print $file $haml2_content;
$file->close;

# change mtime
my $mtime = time;
$mtime += 1000;
utime $mtime, $mtime, $render_haml;

$haml = Text::Haml->new(
	path => [$tempdir],
	cache_dir => $tempdir,
	cache => 2, # using already exists cache
);
$output = $haml->render_file('render.haml');
# same output test 1
is($output, $expected1);

$haml = Text::Haml->new(
	path => $tempdir,
	cache_dir => $tempdir,
	cache => 1,
);
$output = $haml->render_file('render.haml');
is($output, <<'EOF');
<p>
  Read the tutorial for more information.
</p>
EOF
