=pod

=head1 NAME

ARename::RegisterModuleHook - B<arename>'s default hook registration method.

=head1 SYNOPSIS

use ARename::RegisterModuleHook;

# ...

sub register {
    my ($h) = @_;
    register_module_hook('my_default_event', \&my_subroutine, $h);
}

=head1 DESCRIPTION

This module exports one subroutine by default: `I<register_module_hook>'.

That function takes three arguments: A variable, which may be a string, an
array reference or a code reference. The second argument is the code reference
to the subroutine that will do the work (the hook-code, so to speak). The third
argument may be of any of the same kinds of values as the first argument. If it
is defined, it takes precedence over the first argument.

If a code reference is used in the first or the third argument, it must produce
either an array reference or a string. In any case, the result must be one or
more event names (strings) to which the subroutine reference from the second
argument will be registered to within B<arename>.

=head1 SEE ALSO

B<arename(1)>

=head1 AUTHOR

Frank Terbeck <ft@bewatermyfriend.org>

=head1 LICENCE

This extension module is licenced under the same terms as B<arename> itself.

=cut

package ARename::RegisterModuleHook;
use warnings;
use strict;

use Exporter;
@ISA = qw{ register_module_hook };

sub register_module_hook {
    my ($default, $fn, $h) = @_;
    my ($hook);

    $h = $default if (!defined $h);

    if (ref($h) eq 'CODE') {
        $hook = $h->();
    } else {
        $hook = $h;
    }

    $hook = [ $hook ] if (ref($hook) ne 'ARRAY');
    foreach my $event (@{ $hook }) {
        register_hook($event, $fn);
    }
}

1;
