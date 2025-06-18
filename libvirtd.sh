#!/usr/bin/bash

set -xe

/usr/sbin/virtlogd &
/usr/bin/virtstoraged &
/usr/sbin/virtqemud -v -t 0
