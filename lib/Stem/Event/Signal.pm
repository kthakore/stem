package Stem::Event::Signal ;

use Stem::Event::Queue ;

use strict ;
use warnings ;

use base 'Exporter' ;
our @EXPORT = qw( process_signal_queue ) ;

# this generic signal event code needs the safe signals of perl 5.8+

use 5.008 ;

my %signal2event ;

my @signal_queue ;
my %cached_handlers ;

# this sub will cache the handler closures so we can reuse them. 

sub _build {

	my( $self ) = @_ ;

	my $signal = $self->{'signal'} ;

	$self->{'method'} ||= "sig_\L${signal}_handler" ;

# create the signal event handler and cache it.
# we cache them so we can reuse these closures and never leak

	$SIG{ $signal } = $cached_handlers{$signal} ||=
		sub {
			Stem::Event::Queue::queue_has_event() ;
			push @signal_queue, $signal
		} ;

# track the event object for this signal

	$signal2event{$signal} = $self ;

#print "$signal = $SIG{ $signal }\n" ;

# make sure the event queue is set up so we can handle signals in the
# event loop

	Stem::Event::Queue::_init_event_queue() ;

	return ;
}

sub _cancel {

	my( $self ) = @_ ;

	$SIG{ $self->{'signal'} } = 'DEFAULT' ;

	return ;
}

sub process_signal_queue {

	my $sig_count = @signal_queue ;

#print "PROCESS SIGNAL Q $sig_count\n" ;

# return if we have no pending signals

	return $sig_count unless $sig_count ;

	while( my $signal = shift @signal_queue ) {

		my $event = $signal2event{ $signal } ;

		next unless $event ;
		next unless $event->{'active'} ;

		$event->trigger() ;
	}

	return $sig_count ;
}

1 ;
