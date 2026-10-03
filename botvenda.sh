#!/bin/bash
clear

#-----🟢---TECH NET----🟢-------#
source ShellBot.sh

touch lista
[[ ! -e RESET ]] && touch RESET

BOT_DIR="/root/BOT"
ADMIN_FILE="$BOT_DIR/admin_id"
APP_DIR="$BOT_DIR/app"
APP_FILE="$APP_DIR/base.apk"

# ==========================================================
# TOKEN
# ==========================================================

if [[ -z "$1" ]]; then
    clear
    echo "======================================"
    echo "        BOT SSH VPN - CONFIGURAÇÃO"
    echo "======================================"
    read -rsp "INFORME O TOKEN DO BOT: " api_bot
    echo
else
    api_bot="$1"
fi

if [[ -z "$api_bot" ]]; then
    echo "ERRO: token não informado."
    exit 1
fi

if ! curl -fsS "https://api.telegram.org/bot${api_bot}/getMe" | grep -q '"ok":true'; then
    echo "ERRO: token do Telegram inválido."
    exit 1
fi

# ==========================================================
# ADMIN
# ==========================================================

ADMIN_ID=""

if [[ -f "$ADMIN_FILE" ]]; then
    ADMIN_ID="$(tr -d '[:space:]' < "$ADMIN_FILE")"
fi

# ==========================================================
# SHELLBOT
# ==========================================================

ShellBot.init --token "$api_bot" --monitor --flush
ShellBot.username

# ==========================================================
# MENU
# ==========================================================

menu() {

    local chat="${message_chat_id[$id]}"
    local user_id="${message_from_id[$id]}"

    unset keyboard_menu
    keyboard_menu=''

    ShellBot.InlineKeyboardButton \
        --button 'keyboard_menu' \
        --line 1 \
        --text '♻️ GERAR TESTE ⏳' \
        --callback_data 'gerarssh'

    ShellBot.InlineKeyboardButton \
        --button 'keyboard_menu' \
        --line 2 \
        --text '📲 BAIXAR APLICATIVO ⚡' \
        --callback_data 'appenviar'

    ShellBot.InlineKeyboardButton \
        --button 'keyboard_menu' \
        --line 3 \
        --text '💰 COMPRAR ACESSO 🔐' \
        --callback_data 'comprarssh'

    # Administração aparece SOMENTE para o proprietário
    if [[ -n "$ADMIN_ID" && "$user_id" == "$ADMIN_ID" ]]; then

        ShellBot.InlineKeyboardButton \
            --button 'keyboard_menu' \
            --line 4 \
            --text '⚙️ ADMINISTRAÇÃO' \
            --callback_data 'adminmenu'

    fi

    local markup
    markup="$(ShellBot.InlineKeyboardMarkup -b 'keyboard_menu')"

    ShellBot.sendMessage \
        --chat_id "$chat" \
        --parse_mode html \
        --text "╔══════════════════════╗
║ 📶  BOT SSH VPN  📶 ║
╚══════════════════════╝" \
        --reply_markup="$markup" >/dev/null

    return 0
}

# ==========================================================
# GERAR TESTE SSH
# ==========================================================

criarteste() {

    [[ $(grep -wc "${callback_query_from_id}" lista) != '0' ]] && {

        ShellBot.sendMessage \
            --chat_id "${callback_query_message_chat_id}" \
            --text "VC JA CRIOU @NETxL4 SSH HOJE !"

        return 0
    }

    usuario=$(echo lite$(( RANDOM% + 99999 )))
    senha=$((RANDOM% + 99999))
    limite='1'
    tempo='2'

    tuserdate=$(date '+%C%y/%m/%d' -d " +1 days")

    useradd -M -N -s /bin/false "$usuario" -e "$tuserdate" > /dev/null 2>&1

    (echo "$senha";echo "$senha") | passwd "$usuario" > /dev/null 2>&1

    echo "$senha" > "/etc/SSHPlus/senha/$usuario"

    echo "$usuario $limite" >> /root/usuarios.db

    echo "#!/bin/bash
pkill -f \"$usuario\"
userdel --force \"$usuario\"
grep -v ^$usuario[[:space:]] /root/usuarios.db > /tmp/ph
cat /tmp/ph > /root/usuarios.db
rm /etc/SSHPlus/senha/$usuario > /dev/null 2>&1
rm -rf /etc/SSHPlus/userteste/$usuario.sh" \
        > "/etc/SSHPlus/userteste/$usuario.sh"

    chmod +x "/etc/SSHPlus/userteste/$usuario.sh"

    at -f "/etc/SSHPlus/userteste/$usuario.sh" now + "$tempo" hour > /dev/null 2>&1

    echo "${callback_query_from_id}" >> lista

    ShellBot.sendMessage \
        --chat_id "${callback_query_message_chat_id}" \
        --parse_mode html \
        --text "✅ <b>Criado com sucesso</b> ✅

SERVIDOR: BR
USUARIO: <code>$usuario</code>
SENHA: <code>$senha</code>

⏳ Expira em: $tempo Hora"

    return 0
}

# ==========================================================
# ENVIAR APK
# ==========================================================

enviarapp() {

    local chat="${callback_query_message_chat_id[$id]}"

    ShellBot.answerCallbackQuery \
        --callback_query_id "${callback_query_id[$id]}" \
        --text "♻️✉ VERIFICANDO APLICATIVO..."

    if [[ ! -f "$APP_FILE" ]]; then

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ O proprietário ainda não cadastrou um aplicativo."

        return 0
    fi

    ShellBot.sendDocument \
        --chat_id "$chat" \
        --document "@$APP_FILE"

    return 0
}

# ==========================================================
# INFORMAÇÕES DO USUÁRIO
# ==========================================================

infouser() {

    local uid="${message_from_id[$id]}"
    local nome="${message_from_first_name[$id]}"
    local username="${message_from_username[$id]:-null}"

    ShellBot.sendMessage \
        --chat_id "${message_chat_id[$id]}" \
        --parse_mode html \
        --text "Nome: $nome
User: @$username
ID: $uid"

    return 0
}

# ==========================================================
# MENU ADMINISTRATIVO
# ==========================================================

adminmenu() {

    local chat="${callback_query_message_chat_id[$id]}"
    local uid="${callback_query_from_id[$id]}"

    if [[ "$uid" != "$ADMIN_ID" ]]; then

        ShellBot.answerCallbackQuery \
            --callback_query_id "${callback_query_id[$id]}" \
            --text "❌ Acesso não autorizado."

        return 0
    fi

    unset admin_keyboard
    admin_keyboard=''

    ShellBot.InlineKeyboardButton \
        --button 'admin_keyboard' \
        --line 1 \
        --text '📲 ENVIAR / TROCAR APK' \
        --callback_data 'admin_upload'

    ShellBot.InlineKeyboardButton \
        --button 'admin_keyboard' \
        --line 2 \
        --text '🗑️ REMOVER APK' \
        --callback_data 'admin_remove'

    ShellBot.InlineKeyboardButton \
        --button 'admin_keyboard' \
        --line 3 \
        --text '📱 STATUS DO APK' \
        --callback_data 'admin_status'

    ShellBot.InlineKeyboardButton \
        --button 'admin_keyboard' \
        --line 4 \
        --text '↩️ VOLTAR' \
        --callback_data 'admin_back'

    local markup
    markup="$(ShellBot.InlineKeyboardMarkup -b 'admin_keyboard')"

    ShellBot.sendMessage \
        --chat_id "$chat" \
        --parse_mode html \
        --text "⚙️ <b>ADMINISTRAÇÃO</b>

Gerencie o aplicativo que será disponibilizado aos seus clientes." \
        --reply_markup="$markup"

    return 0
}

# ==========================================================
# SOLICITAR APK
# ==========================================================

admin_upload() {

    local chat="${callback_query_message_chat_id[$id]}"
    local uid="${callback_query_from_id[$id]}"

    if [[ "$uid" != "$ADMIN_ID" ]]; then
        return 0
    fi

    mkdir -p "$APP_DIR"
    chmod 700 "$APP_DIR"

    touch "$APP_DIR/.aguardando_apk"
    chmod 600 "$APP_DIR/.aguardando_apk"

    ShellBot.sendMessage \
        --chat_id "$chat" \
        --parse_mode html \
        --text "📲 <b>ENVIAR APK</b>

Envie agora o arquivo <b>.apk</b> neste chat.

O arquivo enviado será usado no botão:
📲 BAIXAR APLICATIVO

⚠️ Somente o proprietário desta instalação pode alterar o APK."

    return 0
}

# ==========================================================
# REMOVER APK
# ==========================================================

admin_remove() {

    local chat="${callback_query_message_chat_id[$id]}"
    local uid="${callback_query_from_id[$id]}"

    if [[ "$uid" != "$ADMIN_ID" ]]; then
        return 0
    fi

    if [[ -f "$APP_FILE" ]]; then
        rm -f "$APP_FILE"
        rm -f "$APP_DIR/.aguardando_apk"

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "🗑️ APK removido com sucesso."
    else

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "ℹ️ Não existe APK cadastrado."
    fi

    return 0
}

# ==========================================================
# STATUS DO APK
# ==========================================================

admin_status() {

    local chat="${callback_query_message_chat_id[$id]}"
    local uid="${callback_query_from_id[$id]}"

    if [[ "$uid" != "$ADMIN_ID" ]]; then
        return 0
    fi

    if [[ -f "$APP_FILE" ]]; then

        local tamanho
        tamanho="$(du -h "$APP_FILE" | awk '{print $1}')"

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --parse_mode html \
            --text "📱 <b>APK CADASTRADO</b>

Arquivo: <code>base.apk</code>
Tamanho: <code>$tamanho</code>

✅ Disponível para seus clientes."
    else

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Nenhum APK cadastrado."
    fi

    return 0
}

# ==========================================================
# RECEBER APK ENVIADO PELO ADMIN
# ==========================================================

receber_apk() {

    local chat="${message_chat_id[$id]}"
    local uid="${message_from_id[$id]}"

    if [[ "$uid" != "$ADMIN_ID" ]]; then
        return 0
    fi

    if [[ ! -f "$APP_DIR/.aguardando_apk" ]]; then
        return 0
    fi

    local document_file_id="${message_document_file_id[$id]}"

    if [[ -z "$document_file_id" ]]; then
        return 0
    fi

    local document_name="${message_document_file_name[$id]}"

    if [[ "${document_name,,}" != *.apk ]]; then

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Envie um arquivo com extensão .apk."

        return 0
    fi

    local file_info
    file_info="$(curl -fsS \
        "https://api.telegram.org/bot${api_bot}/getFile?file_id=${document_file_id}")" || {

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Não foi possível obter o arquivo."

        return 0
    }

    local file_path
    file_path="$(echo "$file_info" | sed -n 's/.*"file_path":"\([^"]*\)".*/\1/p')"

    if [[ -z "$file_path" ]]; then

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Telegram não retornou o arquivo."

        return 0
    fi

    mkdir -p "$APP_DIR"

    local tmp_apk="$APP_DIR/.base.apk.tmp"

    if ! curl -fsS \
        "https://api.telegram.org/file/bot${api_bot}/${file_path}" \
        -o "$tmp_apk"; then

        rm -f "$tmp_apk"

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Falha ao baixar o APK."

        return 0
    fi

    if [[ ! -s "$tmp_apk" ]]; then

        rm -f "$tmp_apk"

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ O arquivo recebido está vazio."

        return 0
    fi

    mv "$tmp_apk" "$APP_FILE"
    chmod 600 "$APP_FILE"

    rm -f "$APP_DIR/.aguardando_apk"

    local tamanho
    tamanho="$(du -h "$APP_FILE" | awk '{print $1}')"

    ShellBot.sendMessage \
        --chat_id "$chat" \
        --parse_mode html \
        --text "✅ <b>APK cadastrado com sucesso!</b>

📱 Arquivo: <code>$document_name</code>
💾 Tamanho: <code>$tamanho</code>

Agora seus clientes poderão usar:
📲 BAIXAR APLICATIVO"

    return 0
}

# ==========================================================
# COMPRAR SSH
# ==========================================================

comprarssh() {

    local chat="${callback_query_message_chat_id[$id]}"

    local dados
    dados="$(/root/BOT/gerar_pix.sh \
        "$chat" \
        "$api_bot" \
        2>/root/BOT/pix_exec_error.log)"

    local payment_id
    payment_id="$(echo "$dados" | sed -n '1p')"

    local qr
    qr="$(echo "$dados" | sed -n '3p')"

    if [[ -z "$payment_id" || -z "$qr" ]]; then

        ShellBot.sendMessage \
            --chat_id "$chat" \
            --text "❌ Não foi possível gerar o Pix agora. Tente novamente."

        return 0
    fi

    ShellBot.sendMessage \
        --chat_id "$chat" \
        --parse_mode html \
        --text "💰 TECH NET — ACESSO SSH 30 DIAS

💵 Valor: R$ 15,00

📲 PIX COPIA E COLA:

<pre>$qr</pre>

👆 Toque em \"COPIAR CÓDIGO\" para copiar.

⏳ Após o pagamento, a confirmação é automática.
🔐 O acesso SSH será enviado aqui neste Telegram.

🧾 ID do pagamento: $payment_id"

    return 0
}

# ==========================================================
# CALLBACKS
# ==========================================================

ShellBot.regHandleFunction \
    --function criarteste \
    --callback_data gerarssh

ShellBot.regHandleFunction \
    --function enviarapp \
    --callback_data appenviar

ShellBot.regHandleFunction \
    --function comprarssh \
    --callback_data comprarssh

ShellBot.regHandleFunction \
    --function adminmenu \
    --callback_data adminmenu

ShellBot.regHandleFunction \
    --function admin_upload \
    --callback_data admin_upload

ShellBot.regHandleFunction \
    --function admin_remove \
    --callback_data admin_remove

ShellBot.regHandleFunction \
    --function admin_status \
    --callback_data admin_status

# ==========================================================
# LOOP
# ==========================================================

while :; do

    [[ "$(date +%d)" != "$(cat RESET)" ]] && {
        echo "$(date +%d)" > RESET
        echo ' ' > lista
    }

    ShellBot.getUpdates \
        --limit 100 \
        --offset $(ShellBot.OffsetNext) \
        --timeout 30

    for id in $(ShellBot.ListUpdates); do

        (

            callback="${callback_query_data[$id]}"

            case "$callback" in

                gerarssh)
                    criarteste
                    ;;

                appenviar)
                    enviarapp
                    ;;

                comprarssh)
                    comprarssh
                    ;;

                adminmenu)
                    adminmenu
                    ;;

                admin_upload)
                    admin_upload
                    ;;

                admin_remove)
                    admin_remove
                    ;;

                admin_status)
                    admin_status
                    ;;

                admin_back)
                    menu
                    ;;

            esac

            # ==================================================
            # RECEBER DOCUMENTO/APK
            # ==================================================

            if [[ -n "${message_document_file_id[$id]}" ]]; then
                receber_apk
            fi

            # ==================================================
            # COMANDOS
            # ==================================================

            comando=(${message_text[$id]})

            if [[ "${comando[0]}" = "/menu" || "${comando[0]}" = "/start" ]]; then
                menu
            fi

            if [[ "${comando[0]}" = "/id" ]]; then
                infouser
            fi

        ) &

    done

done