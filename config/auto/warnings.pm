# Copyright (C) 2007, The Perl Foundation.
# $Id: attributes.pm 21448 2007-09-21 09:29:23Z paultcochrane $

=head1 NAME

config/auto/warnings.pm - Warning flags detection

=head1 DESCRIPTION

Automagically detect what warning flags, like -Wall, -Wextra,
-Wchar-subscripts, etc., that the compiler can support.  Directly hacked
from F<config/auto/attributes.pm>.

=head1 AUTHOR

Paul Cochrane <paultcochrane at gmail dot com>

=cut

package auto::warnings;

use strict;
use warnings;
use vars qw($description @args);

use base qw(Parrot::Configure::Step::Base);

use Parrot::Configure::Step ':auto';
use Parrot::BuildUtil;

$description = 'Detecting supported compiler warnings (-Wxxx)';

@args = qw( cc verbose define );

our @potential_warnings = qw(
    -W
    -Wall
    -Wnot-a-real-warning
);

our $verbose;

sub runstep {
    my ( $self, $conf ) = @_;

    $verbose = $conf->options->get('verbose');
    print $/ if $verbose;

    for my $maybe_warning (@potential_warnings) {
        $self->try_warning( $conf, $maybe_warning );
    }
    return $self;
}

=item C<try_warning>

Try a given warning to see if it is supported by the compiler.  The compiler
is determined by the C<cc> value of the C<Parrot::Configure> object passed
in as the first argument to the method (not counting C<$self>.  The warning
to be checked is passed in as the second argument to the method.

Returns true if the warning flag is recognised by the compiler and undef
otherwise.

=cut

sub try_warning {
    my ( $self, $conf, $warning ) = @_;

    my $output_file = 'test.cco';

    $verbose and print "trying attribute '$warning'$/";

    my $cc = $conf->option_or_data('cc');
    cc_gen('config/auto/warnings/test_c.in');

    my $ccflags  = $conf->data->get('ccflags');
    my $tryflags = "$ccflags $warning";

    my $command_line = Parrot::Configure::Step::_build_compile_command( $cc, $tryflags );
    $verbose and print "  ", $command_line, $/;

    # Don't use cc_build, because failure is expected.
    my $exit_code =
        Parrot::Configure::Step::_run_command( $command_line, $output_file, $output_file );
    $verbose and print "  exit code: $exit_code$/";

    $conf->data->set( $warning => !$exit_code | 0 );

    return if $exit_code;

    my $output = Parrot::BuildUtil::slurp_file($output_file);
    $verbose and print "  output: $output$/";

    if ( $output !~ /error|warning/i ) {
        $conf->data->set( ccflags => $tryflags );
        my $ccflags = $conf->data->get("ccflags");
        $verbose and print "  ccflags: $ccflags$/";
    }

    return;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
