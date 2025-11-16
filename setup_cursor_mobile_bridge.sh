#!/bin/bash
# ================================================================
# 🧠 RC25S - Cursor IDE + Mobile Web IDE Bridge Setup
# ================================================================

set -e
SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"
KEY_FILE="$SSH_DIR/id_ed25519_cursor"
SERVER_NAME="rc25s-server"
HOSTNAME=$(hostname -I | awk "{print \$1}")
USER_NAME="root"
CODE_SERVER_PORT=8080
CODE_SERVER_SERVICE="code-server@$USER"

echo "🚀 [RC25S] Starting full Cursor + Web IDE setup..."

# ================================================================
# STEP 1. SSH Key & Cursor IDE setup
# ================================================================
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$KEY_FILE" ]; then
  echo "🔑 Generating SSH key for Cursor..."
  ssh-keygen -t ed25519 -C "cursor@rc25s" -f "$KEY_FILE" -N ""
fi

if ! grep -q "$(cat $KEY_FILE.pub)" "$SSH_DIR/authorized_keys" 2>/dev/null; then
  echo "📥 Adding SSH key to authorized_keys..."
  cat "$KEY_FILE.pub" >> "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
fi

if ! grep -q "$SERVER_NAME" "$CONFIG_FILE" 2>/dev/null; then
  echo "⚙️  Configuring SSH profile for Cursor IDE..."
  cat >> "$CONFIG_FILE" <<CFG
Host $SERVER_NAME
    HostName $HOSTNAME
    User $USER_NAME
    IdentityFile $KEY_FILE
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
CFG
  chmod 600 "$CONFIG_FILE"
fi

# ================================================================
# STEP 2. Install Code-Server (VSCode in browser)
# ================================================================
if ! command -v code-server >/dev/null 2>&1; then
  echo "📦 Installing code-server..."
  curl -fsSL https://code-server.dev/install.sh | sh
fi

# Enable and start code-server
echo "⚙️  Enabling code-server service..."
systemctl enable --now $CODE_SERVER_SERVICE || true

# ================================================================
# STEP 3. Configure code-server settings
# ================================================================
mkdir -p ~/.config/code-server
cat > ~/.config/code-server/config.yaml <<CONF
bind-addr: 0.0.0.0:$CODE_SERVER_PORT
auth: password
password: rc25s_admin_$(date +%s | sha256sum | head -c 6)
cert: false
CONF

systemctl restart $CODE_SERVER_SERVICE || true

# ================================================================
# STEP 4. Nginx reverse proxy setup for HTTPS access
# ================================================================
NGINX_CONF="/etc/nginx/sites-available/rc25s_webide.conf"

cat > $NGINX_CONF <<NGX
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    location /ide/ {
        proxy_pass http://127.0.0.1:$CODE_SERVER_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
    }
}
NGX

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/rc25s_webide.conf
nginx -t && systemctl reload nginx

# ================================================================
# STEP 5. Summary
# ================================================================
PASSWORD=$(grep password ~/.config/code-server/config.yaml | awk "{print \$2}")

echo "✅ Setup completed successfully!"
echo "------------------------------------------------------------"
echo "💻 Cursor SSH: ssh $SERVER_NAME"
echo "🌐 Mobile IDE URL: https://api.mcpvibe.org/ide/"
echo "🔑 Password: $PASSWORD"
echo "------------------------------------------------------------"
echo "💡 Open Cursor → Connect to Host → rc25s-server"
echo "💡 Open mobile browser → https://api.mcpvibe.org/ide/"
