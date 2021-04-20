#!/bin/bash

# show commands
# set -x

# exit when any command fails
set -euo pipefail
shopt -s inherit_errexit

SKOPEO_BIN="/usr/bin/skopeo"
SRC_TRANSPORT="docker"
SRC_PREFIX="//index.docker.io/"
DST_TRANSPORT="docker-daemon"
IMAGES=""
SKOPEO_GLOBAL_ARGS=""

function print_help() {
  echo "\
USAGE: $0 command [ command options ] [ -- ] [ skopeo global args ]

COMMANDS:
  copy-images (not a regular skopeo command)
    options:
      -s|--src-transport   Default=$SRC_TRANSPORT
      -S|--src-prefix      Default=\"//index.docker.io/\"
      -d|--dst-transport   Default=$DST_TRANSPORT
      -i|--image  List of images separated by commas.  Can be specified multiple
                  times.

  Specifying any other skopeo command will send all arguments to skopeo.
  Any arguments after "--" will be sent to skopeo.

OPTIONS:
  -h|--help   Print this help message.

--  Additional arguments for the skopeo command go after this.

# skopeo help
"
$SKOPEO_BIN -h
}

if [[ $# = 0 ]]; then
  print_help
  exit 1
fi

if [ $1 = "copy-images" ]
then
  shift
  while [[ $# > 0 ]]
    do
    key="$1"
    case $key in
        -d|--dst-transport)
          DST_TRANSPORT="$2"
          shift # past argument
          ;;
        -h|--help)
          print_help
          exit 0
          ;;
        -i|--image)
          if [ -z "$IMAGES" ]
          then
            IMAGES="$2"
          else
            IMAGES+=",$2"
          fi
          shift
          ;;
        -s|--src-transport)
          SRC_TRANSPORT="$2"
          shift # past argument
          ;;
        -S|--src-prefix)
          SRC_PREFIX="$2"
          shift # past argument
          ;;
        --)
          SKOPEO_GLOBAL_ARGS="${@:2}"
          break
          ;;
        *)
          # unknown option
          echo "unknown option: $1"
          print_help
          exit 1
          ;;
    esac
    shift # past argument or value
  done

  if [ -z "$IMAGES" ]; then
    echo "Images have not been specified."
    print_help
    exit 1
  fi

  echo "SRC_TRANSPORT: $SRC_TRANSPORT"
  echo "SRC_PREFIX: $SRC_PREFIX"
  echo "DST_TRANSPORT: $DST_TRANSPORT"
  echo "skopeo global args: $SKOPEO_GLOBAL_ARGS"
  echo "images to copy: $IMAGES"
  echo

  IFS=","
  SKOPEO_COMMANDS=""
  for IMAGE in $IMAGES
  do
    SRC_IMAGE=$SRC_TRANSPORT:$SRC_PREFIX$IMAGE
    DST_IMAGE=$DST_TRANSPORT:$IMAGE
    echo "copying $SRC_IMAGE to $DST_IMAGE"
    SKOPEO_COMMAND="$SKOPEO_BIN $SKOPEO_GLOBAL_ARGS copy $SRC_IMAGE $DST_IMAGE"
    echo "running: \"$SKOPEO_COMMAND\""
    /bin/bash -c $SKOPEO_COMMAND
    echo "copied $SRC_IMAGE to $DST_IMAGE"
    echo
  done
else
  SKOPEO_COMMAND="$SKOPEO_BIN $@"
  echo "running: \"$SKOPEO_COMMAND\""
  /bin/bash -c $SKOPEO_COMMAND
fi
