#!/bin/bash
# Versiob 0.2
# 
NOW=$(date +%s)
DATE=$(date '+%F %T')
POOL="pool.hostname.tld" # Pool hostname
NODE="node.hostname.tld" # Node hostname to compare height
WEBHOOK_URL="https://discord.com/api/webhooks/<replace with your webbhook address>" # URL for channel discord
PING="<@<replace with your discord ID>>" # Discord ID - long number ,  enabled developer mode to get it Format is: <@12345678912345>
NODEHEIGHT="0"
PAYMENTTIME="7200" # Seconds - 2 hours
BLOCKFOUNDTIME="7200" # Seconds - 2 hours
XKRPOOL="NO" # If using XKR orginal pool set YES.


curl --version >/dev/null 2>&1
curl_ok=$?

[[ "$curl_ok" -eq 127 ]] && \
    echo "fatal: curl not installed" && exit 2

# curl exists and runs ok

# Check Kryptokrona Daemon
curl -s -i -H "Accept: application/json" -H "Content-Type:application/json" localhost:11898/getinfo | tr -s ',' '\n' > getinfo

STATUS=$(cat getinfo |grep status | awk -F ":" '{ print $2 }' | tr -d '"')
SYNCED=$(cat getinfo |grep synced | awk -F ":" '{ print $2 }' | tr -d '"')
OUT=$(cat getinfo |grep outgoing_connections_count | awk -F ":" '{ print $2 }' | tr -d '"')
IN=$(cat getinfo |grep incoming_connections_count | awk -F ":" '{ print $2 }' | tr -d '"')
if [ $STATUS =  OK ] && [ $SYNCED = true ] ; then
  echo -e "$DATE - Status $STATUS Synced: $SYNCED"
else
   HEIGHT=$(cat getinfo |grep -E '^"height' | awk -F ":" '{ print $2 }' | tr -d '"\n')
   curl -s -i -H "Accept: application/json" -H "Content-Type:application/json" http://"$NODE":11898/getinfo -o node
   NODEHEIGHT=$(cat node | tr -s ',' '\n' | grep -E '^"height' | awk -F ":" '{ print $2 }' | tr -d '"\n')
   MESSAGE="$PING :loudspeaker: **$POOL** $DATE Kryptokrona daemon not ok.\n Status: __$STATUS__. Synced: __$SYNCED__.\n Pool height: **$HEIGHT** Node ($NODE) height: __$NODEHEIGHT__.\n Connection IN/OUT: **$IN/$OUT**.\n Please investigate"
   echo -e "$DATE - $MESSAGE"
   JSON="{\"content\": \"$MESSAGE\"}"
   curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi

# Check status of pool
curl -s -i -H "Accept: application/json" -H "Content-Type:application/json" https://$POOL/api/stats | tr -s ',' '\n' > stats
  
if [ $XKRPOOL = YES ]; then
   echo -e "XKR Pool health check not supported"
else
   DAEMON=$(grep health stats | awk -F ":" '{ print $4 }'| tr -d '"')
   if [ $DAEMON = ok ] ; then
       echo -e "$DATE - Daemon: $DAEMON"
   else
       MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool daemon not ok.\n Status: __$DAEMON__.\n Please investigate"
       echo -e "$DATE - $MESSAGE"
       JSON="{\"content\": \"$MESSAGE\"}"
       curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
   fi
   WALLET=$(grep wallet stats | awk -F ":" '{ print $2 }' | tr -d '"')
   if [ $WALLET = ok ] ; then
       echo -e "$DATE - Wallet: $WALLET"
   else
      MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool wallet not ok.\n Status __$WALLET__.\n Please investigate"
      echo -e "$DATE - $MESSAGE"
      JSON="{\"content\": \"$MESSAGE\"}"
      curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
   fi
fi

# Check last payment. Depends on hashrate and miners
LASTPAYMENT=$(grep -A 1 -E '^"payments"' stats  |grep -v payments | tr -d '"'  | cut -c -10)
PAYMENTFOUND=$(( $NOW - $LASTPAYMENT ))
PAYM=$(echo "scale=2; $PAYMENTFOUND / 60" | bc)
if [ $PAYMENTFOUND -le $PAYMENTTIME ] ; then
    echo -e "$DATE - Time since last payment: $PAYM minutes"
else
    MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool have not done any payments in __$PAYM__ minutes.\n Low pool hashrate or problem"
    echo -e "$DATE - $MESSAGE"
    JSON="{\"content\": \"$MESSAGE\"}"
    curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi

# Check last block found depends on hashrate and miners
LASTBLOCKFOUND=$(grep -E '^"lastBlockFound"' stats | awk -F ":" '{ print $2 }'| tr -d '"'  | cut -c -10)
BLOCKFOUND=$(( $NOW - $LASTBLOCKFOUND ))
BLOCKM=$(echo "scale=2; $BLOCKFOUND / 60" | bc)
if [ $BLOCKFOUND -le $BLOCKFOUNDTIME  ] ; then
    echo -e "$DATE - Time since last block found: $BLOCKM minutes"
else
   MESSAGE="$PING :loudspeaker: $DATE **$POOL** Pool have not found block since __$BLOCKM__ minutes.\n Low pool hashrate or problem"
   echo -e "$DATE - $MESSAGE"
   JSON="{\"content\": \"$MESSAGE\"}"
   curl -d "$JSON" -H "Content-Type: application/json" "$WEBHOOK_URL"
fi

#Cleanup
rm -f getinfo
rm -f stats
rm -f node