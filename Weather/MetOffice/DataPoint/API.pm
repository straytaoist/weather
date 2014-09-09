package Weather::MetOffice::DataPoint::API;

=head1 NAME

  Weather::MetOffice::DataPoint::API - gateway to the Met Office DataPoint API

=head1 SYNOPSIS

  my $weather = Weather::MetOffice::DataPoint::API->new(
    api_key  => $MY_API_KEY,
    datatype => $json_or_xml, # optional, defaults to JSON
  );

  my %urls = $weather->image_urls;

  my %furls = $weather->forecast_urls;

=head1 DESCRIPTION

This is a wrapper around the Met Office DataPoint API,
making the results of their calls accessible to those of
use who would rather deal with perl, and its datastructures.

=head1 METHODS

=cut

use Moose;

use JSON;
use LWP::Simple;

use constant URL_BASE  => 'http://datapoint.metoffice.gov.uk/public/data';
use constant DATATYPES => [ qw/json xml/ ];

has api_key       => (is => 'ro', isa => 'Str');
has datatype      => (is => 'ro', isa => 'Str');
has image_info    => (is => 'rw', isa => 'HashRef[ArrayRef[Str]]');
has forecast_info => (is => 'rw', isa => 'HashRef[ArrayRef[Str]]');

# there has to be an easier way of doing this...
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %args = @_;
  $args{datatype} ||= DATATYPES->[0];
  if (! (grep $_ eq $args{datatype}, @{ +DATATYPES })) {
    $args{datatype} = DATATYPES->[0];
  }
  return $class->$orig(%args);
};

=head2 new

  my $weather = Weather::MetOffice::DataPoint::API->new(
    api_key  => $MY_API_KEY,
    datatype => $json_or_xml, # optional, defaults to JSON
  );

Make a new instance, using your API key. It won't work if you don't have
one. See below for how to get one.

=cut

=head2 image_urls

  my %urls = $weather->image_urls;

Returns a hash, keyed on the type of image, with a list of
the last nine available images.

Don't repeatedly call this in a tight loop, as it does an API
call each time, and you'll burn through the number you of calls
you are allowed to make, annoy the Met Office and are not being
a Good Citizen. Be nice.

You could find the frequency of the image generation
and use that in a timed loop. (The fastest any of these images is
processed by the Met Office is once every fifteen minutes.)

=cut

sub _fetch_images {
  my $self = shift;
  my $url = sprintf "%s/layer/wxobs/all/%s/capabilities?key=%s",
    URL_BASE, $self->datatype, $self->api_key;
  my $info = decode_json(get($url));
  my $base = $info->{Layers}->{BaseUrl}->{'$'};
  my %image_info;
  for my $detail (@{ $info->{Layers}->{Layer} }) {
    my @urls;
    my $service = $detail->{Service};
    (my $iurl = $base) =~ s/\{LayerName\}/$service->{LayerName}/;
    $iurl =~ s/\{ImageFormat\}/$service->{ImageFormat}/;
    $iurl =~ s/\{key\}/$self->api_key/e;
    for my $time (@{ $service->{Times}->{Time} }) {
      (my $turl = $iurl) =~ s/\{Time\}/$time/;
      push @{ $image_info{$detail->{'@displayName'}} }, $turl;
    }
  }
  $self->image_info({ %image_info });
}

sub image_urls {
  my $self = shift;
  $self->_fetch_images;
  return %{ $self->image_info };
}

=head2 forecast_urls

  my %furls = $weather->forecast_urls;

Returns a hash, keyed on the type of forecast, with a list of
the last available images.

(See image_urls for more info about being a Good Citizen.)

=cut

# This is depressingly close to image_urls, but the internal
# structure isn't quite the same. No doubt I could abstract
# something...
sub _fetch_forecast {
  my $self = shift;
  my $url = sprintf "%s/layer/wxfcs/all/%s/capabilities?key=%s",
    URL_BASE, $self->datatype, $self->api_key;
  my $info = decode_json(get($url));
  my %forecast_info;
  my $base = $info->{Layers}->{BaseUrl}->{'$'};
  for my $detail (@{ $info->{Layers}->{Layer} }) {
    my @urls;
    my $service = $detail->{Service};
    (my $iurl = $base) =~ s/\{LayerName\}/$service->{LayerName}/;
    $iurl =~ s/\{ImageFormat\}/$service->{ImageFormat}/;
    $iurl =~ s/\{key\}/$self->api_key/e;
    (my $turl = $iurl) =~ s/\{DefaultTime\}/$service->{Timesteps}->{'@defaultTime'}/;
    for my $time (@{ $service->{Timesteps}->{Timestep} }) {
      $turl =~ s/\{Timestep\}/$time/;
      push @{ $forecast_info{$detail->{'@displayName'}} }, $turl;
    }
  }
  $self->forecast_info({ %forecast_info });
}

sub forecast_urls {
  my $self = shift;
  $self->_fetch_forecast;
  return %{ $self->forecast_info };
}

=head1 MetOffice Datapoint

You'll need to sign up, to get an API key. You can do that at:

http://www.metoffice.gov.uk/datapoint

(be warned, they send out an HTML-only email, so us mutt
users get raised blood pressure.)

There are usage limits, so please read their T&Cs. No, seriously, do. I
don't want them to withdraw this service, even if it is my
tax dollah that pay for it.

=cut

return qw/I wanted to be with you alone and talk about the weather/;
