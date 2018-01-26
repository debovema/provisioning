#!/bin/sh

inotifywait -m -e modify /etc/wireguard --format '%f' | while read file; do
  case $file in wg0.conf*)
    wg-quick down wg0 && wg-quick up wg0
  esac
done

