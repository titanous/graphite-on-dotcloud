# Graphite on dotCloud

![FUCK YEAH! Graphite in the Cloud](http://fuckyeahnouns.com/images/graphite%20in%20the%20cloud.jpg)

This is a dotCloud service that installs and configures
[Graphite](https://github.com/graphite-project/graphite-web) along with
[statsite](https://github.com/armon/statsite) for all your timeseries metrics
needs. It is by far the fastest and easiest way to get up and running with
Graphite.

## Usage

```sh
git clone https://github.com/titanous/graphite-on-dotcloud.git
cd graphite-on-dotcloud
dotcloud create graphite
dotcloud push graphite
# If the build times out, pushing again should work

# create the graphite database
dotcloud run graphite.graphite python graphite/graphite/manage.py syncdb

# enable basic auth
dotcloud run graphite.graphite enable_basic_auth

# push some sample metrics to carbon
bin/graphite-example.py graphite-foobar.dotcloud.com 1234 1

# relax and play with cute little kittens because you spent five minutes
# setting up Graphite instead of the entire day
open http://graphite-foobar.dotcloud.com/
```

The configuration is pretty basic/generic, feel free to modify things in `conf`.

The graphite sqlite database and the carbon whisper database are both stored in
`~/data` which is migrated to the new instance during each push. There is
currently a few seconds of downtime during each push due to the migration.


## Caveats

The carbon/statsite ports are entirely unsecured, so anyone who knows the
domain/port combos can push metrics to your server.

## License

Copyright 2012 Jonathan Rudenberg. Licensed under the MIT License.

```
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
