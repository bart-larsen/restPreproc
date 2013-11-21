#!/usr/bin/env bash
date
set -xe
while sleep 3h; do
 date
 qstat|grep mprage|grep ' H'|head -n 4|cut -f1 -d.|xargs echo qrls
done
