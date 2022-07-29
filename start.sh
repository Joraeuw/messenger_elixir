#!/bin/bash
# export AMNESIA_DIR=../db

if [ $1 == "dev" ] ; then
  iex -S mix
fi
 
if [ $1 == "all" ] ; then
  echo "Building release..."
  mix release
  echo "Release built successfully"
  echo "testing..."
  mix test --trace 
  echo "Node started"
  _build/dev/rel/messenger/bin/messenger start
  echo "Node stopped"
fi

if [ $1 == "create_db" ] ; then
  mix amnesia.create -d Database --disk -name "messanger@HP455G8"
fi
if [ $1 == "clean_db" ] ; then
  rm -rf ./Mnesia.nonode@nohost
fi

if [ $1 == "build" ] ; then
  echo "Building release..."
  mix release
  echo "Release built"
fi

if [ $1 == "start" ] ; then
  echo "Node started"
  _build/dev/rel/messenger/bin/messenger start
  echo "Node stopped"
fi

if [ $1 == "connect" ] ; then
  _build/dev/rel/messenger/bin/messenger remote
fi

if [ $1 == "stop" ] ; then
  echo "Stopping..."
  _build/dev/rel/messenger/bin/messenger stop
  echo "Node stopped"
fi

if [ $1 == "test" ] ; then
  echo "testing..."
  mix test --trace
fi

if [ $1 == "deps" ] ; then
  mix deps.get
fi