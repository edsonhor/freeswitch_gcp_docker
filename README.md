# docker-freeswitch

Run FreeSWITCH in a Docker container

## Usage

### Build

    $ docker build -t freeswitch .

### Run

Foreground:

    $ docker run -it --net=host -e DEFAULT_PASSWORD=s3cure --name freeswitch freeswitch

Detached:

    $ docker run -itd --net=host -e DEFAULT_PASSWORD=s3cure --name freeswitch freeswitch

#### Runtime Environment Variables

There should be a reasonable amount of flexibility using the available variables. If not please raise an issue so your use case can be covered!

- `DEFAULT_PASSWORD` - The default password, this should always be set to override the default of `1234`
- `EC2` - Configure for EC2/VPC usage - `yes` or `no`, default is `no`

#### Runtime Management

Bring up the FreeSWITCH console:

    $ docker exec -it freeswitch fs_cli

Check the status of the server:

    freeswitch@internal> sofia status profile internal

Exit the console using the `/exit` command.

#### Files and Directories

##### Directories Overview

 * `/etc/freeswitch` - home of all configuration files
 * `/var/log/freeswitch` - log files

##### Configuration Files

 * `/etc/freeswitch/vars.xml`
 * `/etc/freeswitch/sip_profiles/internal.xml`
 * `/etc/freeswitch/sip_profiles/external.xml`
 * `/etc/freeswitch/autoload_configs/switch.conf.xml`

#### Testing the Server

Connect your SIP (e.g. a soft phone) with username `1000` and password `1234`.

Once your container is running and a SIP client connected, test some extensions:

 * `5000` - Default IVR
 * `9195` - five second delay echo test
 * `9196` - standard echo test
 * `9197` - milliwatt extension
 * `9198` - Tetris music
 * `9664` - music on hold

More information: https://wiki.freeswitch.org/wiki/Getting_Started_Guide

### Tag and Push

    $ docker tag freeswitch flaccid/freeswitch
    $ docker push flaccid/freeswitch

License and Authors
-------------------
- Author: Chris Fordham (<chris@fordham-nagy.id.au>)

```text
Copyright 2016, Chris Fordham

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
