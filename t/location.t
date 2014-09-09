#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 11;

use_ok 'Weather::MetOffice::DataPoint::API::Location';

my $api_key = shift or die "Can't do nuttin' for ya man. Pass me an API key";

isa_ok my $weather = Weather::MetOffice::DataPoint::API::Location->new(api_key => $api_key)
  => 'Weather::MetOffice::DataPoint::API::Location';

{
  is $weather->datatype => 'json', 'defaults to JSON';
  my $w2 = Weather::MetOffice::DataPoint::API::Location->new(api_key => $api_key, datatype => 'bah');
  is $w2->datatype => 'json', 'defaults to JSON when given nonsense...';
  my $w3 = Weather::MetOffice::DataPoint::API::Location->new(api_key => $api_key, datatype => 'xml');
  is $w3->datatype => 'xml', '...but we can have XML';
}

{
  my %sites = $weather->sitelist;
  is scalar keys %sites => 5966, '5966 sites (when I wrote this test)';
  is scalar @{ $sites{'54.1774,-2.3369'} } => 2, 'Two sites at 54.1774,-2.3369';
  # just testing it is cached
  %sites = $weather->sitelist;
}

{
  my @info = $weather->site_forecast;
  is scalar @info => 0, 'No data for nowhere';
  @info = $weather->site_forecast('52.1937,0.1268');
  is scalar @info => 1, 'One only weather station in the Botanic Gardens. (I wonder where it is? I must look.)';
  is scalar keys %{ $info[0] } => 5, '5 days of data';
  my @keys = sort { $info[0]->{$a} cmp $info[0]->{$b} } keys %{ $info[0] };
  is scalar @{ $info[0]->{$keys[-1]} } => 8, 'A reading every three hours';
}
