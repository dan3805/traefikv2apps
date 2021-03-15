#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
# inspiration from zendrive-local-scripts
# inspiration from Cloudbox Community
####################################
plexdb="/opt/appdata/plex/database/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plexdocker="plex"
plex=$($(command -v docker) ps -aq --format {{.Names}} | grep -qE 'plex' && echo true || echo false)
if [[ ! -x $(command -v sqlite3) ]]; then apt install sqlite3 -yqq 1>/dev/null 2>&1; fi
if [[ $plex == "true" ]]; then
    $(command -v docker) stop "${plexdocker}"
    cp "$plexdb" "$plexdb.original"
    $(command -v sqlite3) "$plexdb" "DROP index 'index_title_sort_naturalsort'"
    $(command -v sqlite3) "$plexdb" "DELETE from schema_migrations where version='20180501000000'"
    $(command -v sqlite3) "$plexdb" .dump > /tmp/dump.sql
    rm -rf "$plexdb"
    $(command -v sqlite3) "$plexdb" "pragma page_size=32768; vacuum;"
    $(command -v sqlite3) "$plexdb" "pragma default_cache_size=60000"
    $(command -v sqlite3) "$plexdb" < /tmp/dump.sql 
    $(command -v sqlite3) "$plexdb"
    chown 1000:1000 "$plexdb"
    $(command -v docker) start "${plexdocker}"
fi
