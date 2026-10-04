#!/bin/bash
set -euo pipefail

CHAT_ID="${1:-}"
BOT_TOKEN="${2:-}"
VALOR="${3:-15.00}"

TOKEN_FILE="/root/BOT/mercadopago.token"

[[ -n "$CHAT_ID" && -n "$BOT_TOKEN" ]] || exit 1
[[ -s "$TOKEN_FILE" ]] || exit 2

# Aceita 20,00 ou 20.00
VALOR="${VALOR//,/\.}"

# Validação do valor
if ! [[ "$VALOR" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]; then
    echo "VALOR_INVALIDO" >&2
    exit 4
fi

# Converte para duas casas decimais
VALOR="$(printf "%.2f" "$VALOR")"

# Valor precisa ser maior que zero
if ! awk "BEGIN {exit !($VALOR > 0)}"; then
    echo "VALOR_INVALIDO" >&2
    exit 4
fi

TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"

IDEMPOTENCY="$(cat /proc/sys/kernel/random/uuid)"

EMAIL="cliente${CHAT_ID}@technetvpn.com"

DADOS="$(jq -n \
  --arg email "$EMAIL" \
  --arg valor "$VALOR" \
  '{
    transaction_amount: ($valor | tonumber),
    description: "TECH NET - ACESSO SSH 30 DIAS",
    payment_method_id: "pix",
    payer: {
      email: $email
    }
  }')"

RESPOSTA="$(curl -sS -X POST \
  "https://api.mercadopago.com/v1/payments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: $IDEMPOTENCY" \
  -d "$DADOS")"

PAYMENT_ID="$(echo "$RESPOSTA" | jq -r '.id // empty')"

QR="$(echo "$RESPOSTA" | jq -r \
  '.point_of_interaction.transaction_data.qr_code // empty')"

if [[ -z "$PAYMENT_ID" || -z "$QR" ]]; then

    printf "%s\n" "$RESPOSTA" > /root/BOT/pix_error.log

    echo "ERRO" >&2
    echo "$RESPOSTA" >&2

    exit 3
fi

nohup /root/BOT/acompanhar_pagamento.sh \
    "$PAYMENT_ID" \
    "$CHAT_ID" \
    "$BOT_TOKEN" \
    >/dev/null 2>&1 &

echo "$PAYMENT_ID"
echo "$VALOR"
echo "$QR"