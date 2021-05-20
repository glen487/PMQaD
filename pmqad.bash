#!/bin/bash
# Versiob 0.3
# 
NOW=$(date +%s)
DATE=$(date '+%F %T')
NODEHEIGHT="0"

configfile='./config.txt'
source "$configfile"

# Colors
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
HOT="${RED}\xF0\x9F\x94\xA5${NC}"


# curl exists and runs ok

curl --version >/dev/null 2>&1
curl_ok=$?

[[ "$curl_ok" -eq 127 ]] && \
    echo "fatal: curl not installed" && exit 2


# Check Kryptokrona Daemon
curl -s localhost:11898/getinfo -o getinfo

STATUS=$(cat getinfo | jq ."status" | tr -d '"')
SYNCED=$(cat getinfo | jq ."synced")
OUT=$(cat getinfo | jq ."outgoing_connections_count")
IN=$(cat getinfo | jq ."incoming_connections_count")
HEIGHT=$(cat getinfo | jq ."height")
NETWORKHEIGHT=$(cat getinfo | jq ."network_height")
if [ $OUT -lt "1" ];
then
  echo -e "$DATE - Node connections missing IN/OUT: ${RED}$IN/$OUT${NC}"
  MESSAGE="$PING :loudspeaker: **$POOL** $DATE Kryptokrona daemon not ok.\n Connection to low IN/OUT: **$IN/$OUT** .\n Please investigate"
  JSON="{\"content\": \"$MESSAGE\"}"
  curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
else
        echo -e "$DATE - Node connections IN/OUT: $IN/$OUT ${CHECK_MARK}"
fi
if [ $HEIGHT -ne "$NETWORKHEIGHT" ] ;
then
  echo -e "${RED}$DATE Node block hight is less than network $HEIGHT/$NETWORKHEIGHT ${NC}"
  MESSAGE="$PING :loudspeaker: **$POOL** $DATE Kryptokrona daemon not ok.\n Block height is lower than network. $HEIGHT/$NETWORKHEIGHT.\n Please investigate"
  JSON="{\"content\": \"$MESSAGE\"}"
  curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
else
  echo -e "$DATE - Node block height:  $HEIGHT Network: $NETWORKHEIGHT ${CHECK_MARK}"
fi

if [ $STATUS =  OK ] && [ $SYNCED = true ] ; then
  echo -e "$DATE - Node status $STATUS ${CHECK_MARK} Synced: $SYNCED ${CHECK_MARK}"
else
   curl -s http://"$NODE":11898/getinfo -o node
   NODEHEIGHT=$(cat node | jq ."height")
   MESSAGE="$PING :loudspeaker: **$POOL** $DATE XKR daemon not ok.\n Status: $STATUS. Synced: $SYNCED.\n Pool height: **$HEIGHT** Node ($NODE) height: $NODEHEIGHT. \n Connection IN/OUT: **$IN/$OUT**.\n Please investigate"
   echo -e "${RED}$DATE - $MESSAGE ${X_MARK}${NC}"
   JSON="{\"content\": \"$MESSAGE\"}"
   curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi

# Check status of pool
curl -s -o stats  https://$POOL/api/stats

if [ $XKRPOOL = YES ]; then
   echo -e "Pool health check not supported"
else
   DAEMON=$(cat stats | jq ."health.Kryptokrona.daemon" | tr -d '"')
   if [ $DAEMON = ok ] ; then
       echo -e "$DATE - Pool daemon: $DAEMON ${CHECK_MARK}"
   else
       MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool daemon not ok.\n Status: $DAEMON.\n Please investigate"
       echo -e "$DATE - $MESSAGE"
       JSON="{\"content\": \"$MESSAGE\"}"
       curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
   fi
   WALLET=$(cat stats | jq ."health.Kryptokrona.wallet" | tr -d '"')
   if [ $WALLET = ok ] ; then
       echo -e "$DATE - Pool wallet: $WALLET ${CHECK_MARK}"
   else
      MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool wallet not ok.\n Status $WALLET.\n Please investigate"
      echo -e "$DATE - $MESSAGE"
      JSON="{\"content\": \"$MESSAGE\"}"
      curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
   fi
fi

# Check last payment. Depends on hashrate and miners
LASTPAYMENT=$(cat stats |sed "s/.*payments//g" | awk -F "," '{ print $2 }' | tr -d '"' | cut -c -10)
PAYMENTFOUND=$(( $NOW - $LASTPAYMENT ))
PAYM=$(echo "scale=2; $PAYMENTFOUND / 60" | bc)
if [ $PAYMENTFOUND -le $PAYMENTTIME ] ; then
    echo -e "$DATE - Pool last payment: $PAYM min ${CHECK_MARK}"
else
    MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool have not done any payments in $PAYM minutes.\n Low pool hashrate or problem"
    echo -e "$DATE - $MESSAGE"
    JSON="{\"content\": \"$MESSAGE\"}"
    curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi
# Check last block found depends on hashrate and: miners
LASTBLOCKFOUND=$(cat stats |jq ."pool.stats.lastBlockFoundprop" | tr -d '"' | cut -c -10)
BLOCKFOUND=$(( $NOW - $LASTBLOCKFOUND ))
BLOCKM=$(echo "scale=2; $BLOCKFOUND / 60" | bc)
if [ $BLOCKFOUND -le $BLOCKFOUNDTIME  ] ; then
    echo -e "$DATE - Pool last block found: $BLOCKM min ${CHECK_MARK}"
else
   MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool have not found block since $BLOCKM minutes.\n Low pool hashrate or problem"
   echo -e "$DATE - $MESSAGE"
   JSON="{\"content\": \"$MESSAGE\"}"
   curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi

# Check redis server
REDIS=$(redis-cli ping)
if [ $REDIS = PONG ]; then
   echo -e "$DATE - Redis server up ${CHECK_MARK}"
else
   MESSAGE="$PING :loudspeaker: $DATE **$POOL** Redis server did not repsond correct.($REDIS) \n Please investigate"
   echo -e "$DATE - $MESSAGE"
   JSON="{\"content\": \"$MESSAGE\"}"
   curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"

fi

#Cleanup
rm -f getinfo
rm -f stats
rm -f node