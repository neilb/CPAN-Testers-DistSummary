package CPAN::Testers::DistSummary;

use Moo;
use Net::HTTP::Tiny qw(http_get);
use JSON;

has name              => ( is => 'ro' );
has include_developer => ( is => 'ro', default => sub { 0 }, );
has 'version'         => (is => 'rw');
has 'passes'          => (is => 'rw');
has 'fails'           => (is => 'rw');
has 'unknowns'        => (is => 'rw');
has 'pass_rate'       => (is => 'rw');

sub BUILD
{
    my $self   = shift;
    my $letter = substr($self->name, 0, 1);
    my $url    = sprintf('http://www.cpantesters.org/distro/%s/%s.json',
                         $letter,
                         $self->name);
    my $reports = decode_json( http_get($url) );
    my %status;
    my $current_version;
    my $total;

    foreach my $report (@$reports) {
        next if !$self->include_developer
                && ($report->{version} =~ /_\d+$/ || $report->{version} =~ /TRIAL/);
        if (!defined($current_version) || $report->{version} gt $current_version) {
            $current_version = $report->{version};
            %status          = ();
            $total           = 0;
        }
        $status{ $report->{status} }++;
        $total++;
    }

    $self->version($current_version);
    $self->passes(  $status{PASS}    || 0);
    $self->fails(   $status{FAIL}    || 0);
    $self->unknowns( $status{UNKNOWN} || 0);
    if ($total > 0) {
        $self->pass_rate(100.0 * $self->passes / $total );
    }
}

1;

=head1 NAME

CPAN::Testers::DistSummary - get summary of CPAN Tester reports for latest version of a dist

=SYNOPSIS

  use CPAN::Testers::DistSummary;

  my $summary = CPAN::Testers::DistSummary->new(name => 'Module-Path');
  printf "version = %s  pass rate = %.2f\n",
         $summary->version, $summary->pass_rate;

=head1 DESCRIPTION

To follow :-)

=cut

