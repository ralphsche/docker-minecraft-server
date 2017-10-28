#!/bin/bash

shopt -s nullglob

#umask 002
export HOME=/data

if [ ! -e /data/eula.txt ]; then
  if [ "$EULA" != "" ]; then
    echo "# Generated via Docker on $(date)" > eula.txt
    echo "eula=$EULA" >> eula.txt
    if [ $? != 0 ]; then
      echo "ERROR: unable to write eula to /data. Please make sure attached directory is writable by uid=${UID}"
      exit 2
    fi
  else
    echo ""
    echo "Please accept the Minecraft EULA at"
    echo "  https://account.mojang.com/documents/minecraft_eula"
    echo "by adding the following immediately after 'docker run':"
    echo "  -e EULA=TRUE"
    echo ""
    exit 1
  fi
fi

if ! touch /data/.verify_access; then
  echo "ERROR: /data doesn't seem to be writable. Please make sure attached directory is writable by uid=${UID} "
  exit 2
fi

export SERVER_PROPERTIES=/data/server.properties
export FTB_DIR=/data/FeedTheBeast
export VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json

echo "Checking version information."
case "X$VERSION" in
  X|XLATEST|Xlatest)
    export VANILLA_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
  XSNAPSHOT|Xsnapshot)
    export VANILLA_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.snapshot'`
  ;;
  X[1-9]*)
    export VANILLA_VERSION=$VERSION
  ;;
  *)
    export VANILLA_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
esac

cd /data

echo "Checking type information."
case "$TYPE" in
  *BUKKIT|*bukkit|SPIGOT|spigot)
    su-exec minecraft /start-deployBukkitSpigot $@
  ;;

  PAPER|paper)
    su-exec minecraft /start-deployPaper $@
  ;;

  FORGE|forge)
    su-exec minecraft /start-deployForge $@
  ;;

  FTB|ftb)
    su-exec minecraft /start-deployFTB $@
  ;;

  VANILLA|vanilla)
    su-exec minecraft /start-deployVanilla $@
  ;;

  *)
      echo "Invalid type: '$TYPE'"
      echo "Must be: VANILLA, FORGE, BUKKIT, SPIGOT, PAPER, FTB"
      exit 1
  ;;

esac
