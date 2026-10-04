#!/bin/bash
cd /root/BOT
source /root/BOT/botvenda.env
exec /bin/bash /root/BOT/botvenda "$BOT_TOKEN"
