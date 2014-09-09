weather
=======

Simple wrapper around the Met Office's DataPoint API.

TESTING
=======

I do:

perl -w Weather/t/api.t `cat api_key`
perl -w Weather/t/location.t `cat api_key`

where the file api_key is, quite evidently, the api key
I got when I signed up to get access.

Look, I know, right?

API KEY
=======

Go:

http://www.metoffice.gov.uk/datapoint

and do what you need to do.
