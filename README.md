PMQaD - Pool Monitor Quick and Dirty
====================================

#### Basic features
Monitor [cryptonote-nodejs-pool](https://github.com/dvandal/cryptonote-nodejs-pool) quick and dirty checks with bash script. 
The script checks to node and pool health and send alert to discord channel with webhook. 
Ping a specific user supported.

Primary made for [Kryptokrona Pools](https://www.kryptokrona.se) and [Github](https://github.com/kryptokrona/) but might work for others with small adjustmnents.

#### Functions
* Check node daemon status (kryptokrona)
 * Status
 * Synced
 * Incoming Connections
 * Outgoing Connections
* Compare block height with another node
* Verify pool health (XKR pool do not support this set XKRPOOL="YES" to skip check)
 * Daemon
 * Wallet
* Pool last payment
* Pool lastblockfound
* Redis server running

#### Changes

* 0.1 First release
* 0.2 Add some formating and loudspeaker icon
* 0.3 Moved settings to: config.cfg. Added node connections and redis-server checks. Changed parsing of json output to using "jq" instead. Added emoji codes.  

#### Requirement 

For Debian/Ubuntu:

```bash
sudo apt install curl
sudo apt install bc
```

#### 1) Downloading & Installing

Clone the repository

```bash
git clone https://github.com/glen487/PMQaD
cd PMQaD
sudo chmod +x pmqad.bash
sed -i -e 's/\r$//' pmqad.bash
```

#### 2) Configure
Edit the config.cfg and adjust to your needs.

* POOL - hostname.domain.tld
* NODE - hostname.domain.tld
* WEBHOOK_URL - URL Webhook to discord channel
* PING - To ping a specific user add Discord user id (long one @1234566789123456) enabled developer mode under advanced settings. 
* Adjust the PAYMENTTIME and BLOCKFOUNDTIME time depending on your pools need. Depends on numbers of miners, pool and total network hashrate.
* XKRPOOL - YES if pool is based on orginal Kryptokrona Pool to not support pool health checks.
* Script expected to be running local on the pool and checks pool node via local host.
* Pool API is checked via pool hostname and expected that HTTPS is used and API is served via https://<pool hostname.tld>/api/stats. Change to HTTP and localhost:port if needed.

#### 3) Cronjob

```bash
crontab -e

# Add to run every 15 min
15 * * * * ./pmqad.bash
```

#### Sample config.cfg

```
POOL="floki.kryptokrona.se" # Pool hostname
NODE="gota.kryptokrona.se" # Node hostname to compare height
WEBHOOK_URL="https://discord.com/api/webhooks/<replace with your webbhook address>" # URL for channel discord
PING="<@<replace with your discord ID>>" # Discord ID - long number ,  enabled developer mode to get it Format is: <@12345678912345>
PAYMENTTIME="7200" # Seconds - 2 hours
BLOCKFOUNDTIME="3600" # Seconds - 1 hours
XKRPOOL="NO" # If using XKR orginal pool set to YES
```

#### Sample output
```bash
2021-05-20 07:50:51 - Node connections IN/OUT: 0/6 ✔
2021-05-20 07:50:51 - Node block height:  711366 Network: 711366 ✔
2021-05-20 07:50:51 - Node status OK ✔ Synced: true ✔
2021-05-20 07:50:51 - Pool daemon: ok ✔
2021-05-20 07:50:51 - Pool wallet: ok ✔
2021-05-20 07:50:51 - Pool last payment: 54.31 min ✔
2021-05-20 07:50:51 - Pool last block found: 42.21 min ✔
2021-05-20 07:50:51 - Redis server up ✔
```

License
-------
N/A
