package Utils;

use strict;
use warnings FATAL => 'all';

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    to_pretty_json
);
our @EXPORT = @EXPORT_OK;

sub to_pretty_json {
    my ($data) = @_;

    my $json_coder = JSON::PP
        ->new
        ->pretty
        ->canonical
        ->indent_length(4)
        ;

    my $pretty_json = $json_coder->encode($data);

    return $pretty_json;
}

1;
