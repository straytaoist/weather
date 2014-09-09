#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 12;

use_ok 'Weather::MetOffice::DataPoint::API';

my $api_key = shift or die "Can't do nuttin' for ya man. Pass me an API key";

isa_ok my $weather = Weather::MetOffice::DataPoint::API->new(api_key => $api_key)
  => 'Weather::MetOffice::DataPoint::API';

{
  is $weather->datatype => 'json', 'defaults to JSON';
  my $w2 = Weather::MetOffice::DataPoint::API->new(api_key => $api_key, datatype => 'bah');
  is $w2->datatype => 'json', 'defaults to JSON when given nonsense...';
  my $w3 = Weather::MetOffice::DataPoint::API->new(api_key => $api_key, datatype => 'xml');
  is $w3->datatype => 'xml', '...but we can have XML';
}

{
  my %urls = $weather->image_urls;
  is scalar @{ $urls{Rainfall} } => 13, 'Thirteen rainfall image urls';
  is scalar @{ $urls{SatelliteVis} } => 9, 'Nine rainfall image urls';
}

{
  my %urls = $weather->forecast_urls;
  is scalar @{ $urls{Cloud} }    => 13, 'Thirteen cloud image urls';
  is scalar @{ $urls{Pressure} } => 7,  'Seven pressure image urls';
}

{
  my @surpress = $weather->surface_pressure;
  ok scalar @surpress > 1, 'Some surface pressure entries';
}

{
  my %extremes = $weather->extremes;
  is scalar keys %extremes => 17, '17 extreme data points';
  is scalar keys $extremes{'Northern Ireland'} => 6, '6 regional datapoints';
}
