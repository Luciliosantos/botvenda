#!/bin/bash
set -u
PAYMENT_ID="${1:-}"
CHAT_ID="${2:-}"
BOT_TOKEN="${3:-}"
TOKEN_FILE="/root/BOT/mercadopago.token"
DONE_DIR="/root/BOT/pagamentos"
mkdir -p "$DONE_DIR"
[[ -n "$PAYMENT_ID" && -n "$CHAT_ID" && -n "$BOT_TOKEN" ]] || exit 1
[[ -s "$TOKEN_FILE" ]] || exit 1
TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
DONE="$DONE_DIR/$PAYMENT_ID.done"
[[ -f "$DONE" ]] && exit 0
while true; do
  RESPOSTA="$(curl -sS -H "Authorization: Bearer $TOKEN" "https://api.mercadopago.com/v1/payments/$PAYMENT_ID")"
  STATUS="$(echo "$RESPOSTA" | jq -r '.status // empty')"
  if [[ "$STATUS" == "approved" ]]; then
    while true; do
      USUARIO="ssh$(shuf -i 10000-99999 -n 1)"
      id "$USUARIO" >/dev/null 2>&1 || break
    done
    SENHA="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)"
    DATA="$(date -d '+30 days' '+%Y-%m-%d')"
    useradd -M -N -s /bin/false -e "$DATA" "$USUARIO" || exit 1
    echo "$USUARIO:$SENHA" | chpasswd
    mkdir -p /etc/SSHPlus/senha /etc/SSHPlus/userteste
    printf '%s\n' "$SENHA" > "/etc/SSHPlus/senha/$USUARIO"
    chmod 600 "/etc/SSHPlus/senha/$USUARIO"
    [[ -f /root/usuarios.db ]] && printf '%s 1\n' "$USUARIO" >> /root/usuarios.db
    CLEAN="/etc/SSHPlus/userteste/$USUARIO.sh"
    printf '%s\n' '#!/bin/bash' "userdel -f "$USUARIO" 2>/dev/null || true" "rm -f "/etc/SSHPlus/senha/$USUARIO"" "sed -i "/^$USUARIO /d" /root/usuarios.db 2>/dev/null || true" "rm -f "$CLEAN"" > "$CLEAN"
    chmod 700 "$CLEAN"
    at -f "$CLEAN" now + 30 days >/dev/null 2>&1 || true
    curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" --data-urlencode "text=✅ ✘Criado com sucesso✘ ✅

SERVIDOR: BR
USUARIO: ${USUARIO}
SENHA: ${SENHA}
⏳ Expira em: 30 dias" -d "parse_mode=HTML" >/dev/null
    touch "$DONE"
    exit 0
  fi
  [[ "$STATUS" == "rejected" || "$STATUS" == "cancelled" || "$STATUS" == "expired" ]] && exit 0
  sleep 15
done
