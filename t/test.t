# -*- perl -*-

use strict;
use warnings;

use Test::More;
use File::Find ();
use Capture::Tiny ':all';

use vars qw/*name *dir *prune/;
*name  = *File::Find::name;
*dir   = *File::Find::dir;
*prune = *File::Find::prune;
my $num_plugins = 0;

sub wanted {
    my ( $dev, $ino, $mode, $nlink, $uid, $gid, $interpreter, $arguments );

    ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
        && -f _
        && ( ( $interpreter, $arguments ) = hashbang("$_") )
        && ($interpreter)
        && ++$num_plugins
        && process_file( $_, $name, $interpreter, $arguments );
}

File::Find::find( { wanted => \&wanted }, 'plugins' );

sub hashbang {
    my ($filename) = @_;
    open my $file, '<', $filename;
    my $firstline = <$file>;
    close $file;

    $firstline =~ m{ ^\#!                    # hashbang
                     \s*                     # optional space
                     (?:/usr/bin/env\s+)?    # optional /usr/bin/env
                     (?<interpreter>\S+)     # interpreter
                     (?:\s+
                         (?<arguments>[^\n]*)   # optional interpreter arguments
                     )?
               }xms;

    return ( $+{interpreter}, $+{arguments} );
}

sub process_file {
    my ( $file, $filename, $interpreter, $arguments ) = @_;
    use v5.10.1;

    if ( $interpreter =~ m{/bin/sh} ) {
        subtest $filename => sub {
            plan tests => 2;
            run_check(
                {   command     => [ 'sh', '-n', $file ],
                    description => 'sh syntax check',
                    filename    => $filename,
                }
            );
            run_check(
                {   command     => [ 'checkbashisms', $file ],
                    description => 'checkbashisms',
                    filename    => $filename,
                }
            );
            run_check(
                {   command     => [ 'shellcheck', $file ],
                    description => 'shellcheck',
                    filename    => $filename,
                }
            );
        };
    }
    elsif ( $interpreter =~ m{/bin/ksh} ) {
        run_check(
            {   command     => [ 'ksh', '-n', $file ],
                description => 'ksh syntax check',
                filename    => $filename,
            }
            );
        run_check(
            {   command     => [ 'shellcheck', $file ],
                description => 'shellcheck',
                filename    => $filename,
            }
        );
    }
    elsif ( $interpreter =~ m{perl} ) {
        my $command;
        if ( $arguments =~ m{-.*T}mx ) {
            $command = [ 'perl', '-cwT', $file ];
        }
        else {
            $command = [ 'perl', '-cw', $file ];
        }
        run_check(
            {   command     => $command,
                description => 'perl syntax check',
                filename    => $filename
            }
        );
    }
    else {
        fail( $filename . " unknown interpreter " . $interpreter );
    }
}

sub run_check {
    my ($args)        = @_;
    my $check_command = $args->{command};
    my $description   = $args->{description};
    my $filename      = $args->{filename};

    my $message;

    if ($filename) {
        $message = sprintf( '%s: %s', $filename, $description );
    }
    else {
        $message = $description;
    }

    my ( $stdout, $stderr, $exit ) = capture {
        system( @{$check_command} );
    };

    ok( ( $exit == 0 ), $message );

    if ($exit) {
        diag(
            sprintf(
                "\nCommand: %s\n\nSTDOUT:\n\n%s\n\nSTDERR:\n\n%s\n\n",
                join( " ", @{$check_command} ),
                $stdout, $stderr
            )
        );
    }
}

done_testing($num_plugins);
