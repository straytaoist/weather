package Weather::MetOffice::DataPoint::API::Location;

=head1 NAME

  Weather::MetOffice::DataPoint::API::Location - MO DP locations

=head1 SYNOPSIS

  blahblah

=head1 METHODS

=cut

use Moose;
use LWP::Simple; # can't I....?
use JSON; # ...and also?

extends 'Weather::MetOffice::DataPoint::API';

has total_sitelist   => (is => 'rw', isa => 'HashRef[ArrayRef]');
has total_regionlist => (is => 'rw', isa => 'HashRef[Int]');

=head2 sitelist

  my %all_locs = $weather->sitelist;

A list of *all* sites. The motherload. About 400kb of info.

The values are ARRAYREFs, and the key is lat/lon. Because there
are multiple stations at the same lat/lon, it seems.

=cut

sub _fetch_sitelist {
  my $self = shift;
  my $url = sprintf "%s/val/wxfcs/all/%s/sitelist?key=%s",
    $self->URL_BASE, $self->datatype, $self->api_key;
  my $info = decode_json(get($url));
  my %sl;
  for my $detail (@{ $info->{Locations}->{Location} }) {
    # I'm thinking this is the way to disambiguate...
    my $loc = sprintf "%s,%s", $detail->{latitude}, $detail->{longitude};
    push @{ $sl{$loc} }, $detail;
  }
  $self->total_sitelist({ %sl });
}

sub sitelist {
  my $self = shift;
  $self->_fetch_sitelist unless $self->total_sitelist;
  return %{ $self->total_sitelist };
}

=head2 site_forecast

  my @forecast = $weather->site_forecast($lat_lon);

Given a lat/lon, get the forecast. Returns a list as
there could be more than one station at the lat/lon. Yeah,
I know. You get values for every three-hour period going back
a few days.

TODO: Get the closest station to the lat/lon given. For now,
if you don't get it right, you'll not get any data. But you
can grab a key from the sitelist if you want to test...

This returns all sorts of good stuff. Here is part of the key:

D  => wind direction in 16-point compass direction
H  => screen relative humidity in percent
G  => wind gust in mph
W  => Significant weather for 0 (clear night) to 30 (thunder)
Pp => percipitation probability as a percentage
T  => screen temperature in Celsius
S  => wind speed in mph
F  => 'feels like' temperature
V  => visibility (in m, or as a code, eg PO = poor)
U  => strength of the sun's UV in Solar UV Index
P  => mean sea level pressure in hPa

=cut

sub site_forecast {
  my ($self, $lat_lon) = @_;
  my @site_info;
  if (my $ref = $self->total_sitelist->{$lat_lon || ''}) {
    for my $data (@$ref) {
      my $url = sprintf "%s/val/wxfcs/all/%s/%s?res=%s&key=%s",
        $self->URL_BASE, $self->datatype, $data->{id},
        '3hourly', $self->api_key; # ignoring 'daily' for now
      my $info = decode_json(get($url));
      my %data;
      for my $detail (@{ $info->{SiteRep}->{DV}->{Location}->{Period} }) {
        $data{$detail->{value}} = $detail->{Rep};
      }
      push @site_info, { %data };
    }
  }
  return @site_info;
}

=head2 regionlist

  my %regions = $weather->regionlist;

All the regions, so you get regional forecasts.

=cut

sub _fetch_regionlist {
  my $self = shift;
  my $url = sprintf "%s/txt/wxfcs/regionalforecast/%s/sitelist?key=%s",
    $self->URL_BASE, $self->datatype, $self->api_key;
  my $info = decode_json(get($url));
  my %rl;
  for my $detail (@{ $info->{Locations}->{Location} }) {
    $rl{$detail->{'@name'}} = $detail->{'@id'};
  }
  $self->total_regionlist({ %rl });
}

sub regionlist {
  my $self = shift;
  $self->_fetch_regionlist unless $self->total_regionlist;
  return %{ $self->total_regionlist };
}

=head2 region_forecast

  my @forecast = $weather->region_forecast($region);

Get the regional forecast, using a region. You can get
those above.

The list is in chronological order, most recent first.

=cut

sub region_forecast {
  my ($self, $region) = @_;
  my @r_info;
  if (my $id = $self->total_regionlist->{$region || ''}) {
    my $url = sprintf "%s/txt/wxfcs/regionalforecast/%s/%s?&key=%s",
      $self->URL_BASE, $self->datatype, $id, $self->api_key;
    my $info = decode_json(get($url));
    for my $detail (@{ $info->{RegionalFcst}->{FcstPeriods}->{Period} }) {
      $detail->{Paragraph} = [ $detail->{Paragraph} ] unless ref $detail->{Paragraph} eq 'ARRAY';
      for my $more (@{ $detail->{Paragraph} }) {
        $more->{title} =~ s/:$//;
        push @r_info, {
          title   => $more->{title},
          summary => $more->{'$'},
        };
      }
    }
  }
  return @r_info;
}

return qw/where is your head at/;
