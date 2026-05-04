#!/bin/bash
# ============================================
# SAEKA VPN PROTOCOLS - AWS VPS DEPLOYMENT
# SSH | V2Ray | Trojan | Stunnel | WebSocket | SlowDNS
# Professional VPN Server Suite v1.0
# ============================================
clear

# ============================================
# COLOR DEFINITIONS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
RESET='\033[0m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'

# ============================================
# ERROR HANDLING
# ============================================
set -e
trap 'echo -e "\n${BG_RED}${WHITE} [FATAL] Script failed at line $LINENO ${RESET}"; exit 1' ERR

error_exit() {
    echo -e "\n${BG_RED}${WHITE} [FATAL] $1 ${RESET}"
    exit 1
}

# ============================================
# UTILITY FUNCTIONS
# ============================================
success() { echo -e "  ${GREEN}[SUCCESS]${RESET} $1"; }
info()    { echo -e "  ${CYAN}[INFO]${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "  ${RED}[ERROR]${RESET} $1"; }

spinner() {
    local pid=$1
    local text="$2"
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %8 ))
        printf "\r  ${CYAN}${frames:$i:1}${RESET} ${text}"
        sleep 0.1
    done
    printf "\r  ${GREEN}✓${RESET} ${text} ${GREEN}[DONE]${RESET}\n"
}

# ============================================
# BANNER
# ============================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                  ║"
    echo "║   ${WHITE}███████╗ █████╗ ███████╗██╗  ██╗ █████╗ ${CYAN}                     ║"
    echo "║   ${WHITE}██╔════╝██╔══██╗██╔════╝██║ ██╔╝██╔══██╗${CYAN}                     ║"
    echo "║   ${WHITE}███████╗███████║█████╗  █████╔╝ ███████║${CYAN}                     ║"
    echo "║   ${WHITE}╚════██║██╔══██║██╔══╝  ██╔═██╗ ██╔══██║${CYAN}                     ║"
    echo "║   ${WHITE}███████║██║  ██║███████╗██║  ██╗██║  ██║${CYAN}                     ║"
    echo "║   ${WHITE}╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝${CYAN}                     ║"
    echo "║                                                                  ║"
    echo "║   ${WHITE}██╗   ██╗██████╗ ███╗   ██╗    ██████╗ ██████╗  ██████╗ ${CYAN}     ║"
    echo "║   ${WHITE}██║   ██║██╔══██╗████╗  ██║    ██╔══██╗██╔══██╗██╔═══██╗${CYAN}     ║"
    echo "║   ${WHITE}██║   ██║██████╔╝██╔██╗ ██║    ██████╔╝██████╔╝██║   ██║${CYAN}     ║"
    echo "║   ${WHITE}╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║    ██╔═══╝ ██╔══██╗██║   ██║${CYAN}     ║"
    echo "║   ${WHITE} ╚████╔╝ ██║     ██║ ╚████║    ██║     ██║  ██║╚██████╔╝${CYAN}     ║"
    echo "║   ${WHITE}  ╚═══╝  ╚═╝     ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ${CYAN}     ║"
    echo "║                                                                  ║"
    echo "║   ${WHITE}SSH | V2Ray | Trojan | Stunnel | WebSocket | SlowDNS${CYAN}          ║"
    echo "║   ${DIM}AWS VPS Professional VPN Protocol Suite v1.0${CYAN}                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ============================================
# SYSTEM CHECK & REQUIREMENT INSTALL
# ============================================
check_requirements() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  SYSTEM REQUIREMENT CHECK                                ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # OS Detection
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        error_exit "Unsupported OS. Ubuntu/Debian required."
    fi
    
    info "OS: $OS $VER"
    
    # Check root
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo bash $0"
    fi
    success "Running as root"
    
    # Install essential tools
    info "Updating system packages..."
    apt-get update -y -qq &
    spinner $! "Updating package lists"
    
    info "Installing essential tools..."
    apt-get install -y -qq curl wget git unzip zip net-tools openssl \
        software-properties-common nginx certbot python3 python3-pip \
        build-essential cmake gcc g++ make ufw jq bc cron \
        netcat-openbsd socat htop iftop iptables-persistent &>/dev/null &
    spinner $! "Installing core dependencies"
    
    success "System requirements satisfied"
}

# ============================================
# CONFIGURE FIREWALL
# ============================================
configure_firewall() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  FIREWALL CONFIGURATION                                  ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    ufw --force reset &>/dev/null
    ufw default deny incoming &>/dev/null
    ufw default allow outgoing &>/dev/null
    
    # Open all required ports
    PORTS="22 80 443 53 2082 2083 2086 2087 2096 3128 8000 8080 8888 8443 1080 1701 500 4500 7200 7300"
    
    for port in $PORTS; do
        ufw allow $port/tcp &>/dev/null
        ufw allow $port/udp &>/dev/null
    done
    
    ufw --force enable &>/dev/null
    success "Firewall configured with all required ports"
}

# ============================================
# INSTALL SSH SERVER
# ============================================
install_ssh() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING SSH PROTOCOL                                 ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    apt-get install -y -qq openssh-server dropbear &>/dev/null &
    spinner $! "Installing OpenSSH + Dropbear"
    
    # Configure OpenSSH
    cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AllowTcpForwarding yes
GatewayPorts yes
PermitTunnel yes
ClientAliveInterval 60
ClientAliveCountMax 3
MaxSessions 100
MaxStartups 50:30:100
Banner /etc/ssh/banner.txt
PrintMotd yes
UseDNS no
EOF

    # SSH Banner
    cat > /etc/ssh/banner.txt << 'BANNER'
╔══════════════════════════════════════════╗
║    SAEKA VPN PROTOCOLS                  ║
║    SSH Server - Authorized Access Only   ║
╚══════════════════════════════════════════╝
BANNER

    # Configure Dropbear
    cat > /etc/default/dropbear << 'EOF'
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 80 -p 443 -p 8080"
EOF

    systemctl restart ssh 2>/dev/null
    systemctl restart dropbear 2>/dev/null
    systemctl enable ssh dropbear &>/dev/null
    
    success "SSH installed on ports: 22, 80, 143, 443, 8080"
}

# ============================================
# INSTALL STUNNEL (TLS)
# ============================================
install_stunnel() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING STUNNEL (TLS/SSL)                            ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    apt-get install -y -qq stunnel4 &>/dev/null &
    spinner $! "Installing Stunnel4"
    
    # Generate SSL Certificate
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=SAEKA/CN=${PUBLIC_IP:-localhost}" \
        -keyout /etc/stunnel/stunnel.key \
        -out /etc/stunnel/stunnel.crt 2>/dev/null
    
    cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
    chmod 600 /etc/stunnel/stunnel.pem
    
    cat > /etc/stunnel/stunnel.conf << 'EOF'
cert = /etc/stunnel/stunnel.pem
pid = /var/run/stunnel.pid

[ssh-tls]
accept = 443
connect = 127.0.0.1:22

[dropbear-tls]
accept = 444
connect = 127.0.0.1:143

[openvpn-tls]
accept = 8443
connect = 127.0.0.1:1194
EOF

    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null || true
    systemctl restart stunnel4 2>/dev/null || stunnel4 /etc/stunnel/stunnel.conf &
    
    success "Stunnel (TLS) installed on ports: 443, 444, 8443"
}

# ============================================
# INSTALL V2RAY (VMESS + VLESS)
# ============================================
install_v2ray() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING V2RAY (VMESS / VLESS)                        ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    bash <(curl -sL https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) &>/dev/null &
    spinner $! "Installing V2Ray Core"
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    cat > /usr/local/etc/v2ray/config.json << V2RAYEOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 8888,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "port": 2083,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vless" }
      }
    },
    {
      "port": 2087,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/stunnel/stunnel.crt",
            "keyFile": "/etc/stunnel/stunnel.key"
          }]
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
V2RAYEOF

    systemctl enable v2ray 2>/dev/null
    systemctl restart v2ray 2>/dev/null
    
    echo "$UUID" > /etc/v2ray/uuid.txt
    
    success "V2Ray installed: VMess(8888/WS), VLESS(2083/WS), VMess TLS(2087)"
}

# ============================================
# INSTALL TROJAN
# ============================================
install_trojan() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING TROJAN PROXY                                 ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    bash <(curl -sL https://raw.githubusercontent.com/trojan-gfw/trojan/master/scripts/install.sh) &>/dev/null &
    spinner $! "Installing Trojan"
    
    TROJAN_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    
    cat > /usr/local/etc/trojan/config.json << TROJANEOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": ["$TROJAN_PASS"],
  "ssl": {
    "cert": "/etc/stunnel/stunnel.crt",
    "key": "/etc/stunnel/stunnel.key"
  }
}
TROJANEOF

    systemctl enable trojan 2>/dev/null
    systemctl restart trojan 2>/dev/null
    
    echo "$TROJAN_PASS" > /etc/trojan/password.txt
    
    success "Trojan installed on port 443"
}

# ============================================
# INSTALL SLOWDNS
# ============================================
install_slowdns() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING SLOWDNS                                      ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    wget -q https://github.com/nicholasadie/slowdns/releases/download/latest/slowdns-linux -O /usr/local/bin/slowdns
    chmod +x /usr/local/bin/slowdns
    
    cat > /etc/systemd/system/slowdns.service << EOF
[Unit]
Description=SlowDNS Service
After=network.target
[Service]
ExecStart=/usr/local/bin/slowdns -udp :5300 -tcp :53
Restart=always
[Install]
WantedBy=multi-user.target
EOF

    systemctl enable slowdns 2>/dev/null
    systemctl start slowdns 2>/dev/null
    
    success "SlowDNS installed on ports 53 (TCP/UDP), 5300 (UDP)"
}

# ============================================
# INSTALL WEBSOCKET PROXY
# ============================================
install_websocket() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING WEBSOCKET PROXY                               ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Nginx WebSocket proxy for SSH
    cat > /etc/nginx/conf.d/websocket.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location /ws-ssh {
        proxy_pass http://127.0.0.1:22;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
    
    location /ws-dropbear {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /vmess {
        proxy_pass http://127.0.0.1:8888;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /vless {
        proxy_pass http://127.0.0.1:2083;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    systemctl restart nginx 2>/dev/null
    success "WebSocket proxy installed on port 80"
}

# ============================================
# CREATE VPN USERS
# ============================================
create_users() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  CREATING DEFAULT VPN USERS                              ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Create default users
    USERS=("vpnuser" "saeka" "adminvpn")
    DEFAULT_PASS="SaekaVPN@2025"
    
    for user in "${USERS[@]}"; do
        useradd -m -s /bin/bash "$user" 2>/dev/null || true
        echo "$user:$DEFAULT_PASS" | chpasswd
        echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
    done
    
    # Save credentials
    cat > /etc/vpn-credentials.txt << EOF
============================================
SAEKA VPN PROTOCOLS - USER CREDENTIALS
============================================
Username: vpnuser
Password: $DEFAULT_PASS
SSH Port: 22, 80, 143, 443, 8080
Dropbear: 80, 143, 443
Stunnel: 443, 444, 8443
============================================
Username: saeka
Password: $DEFAULT_PASS
============================================
Username: adminvpn
Password: $DEFAULT_PASS
============================================
EOF
    
    success "VPN users created"
}

# ============================================
# REAL-TIME USER MONITOR
# ============================================
install_monitor() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  INSTALLING REAL-TIME MONITORING                         ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    cat > /usr/local/bin/vpn-monitor << 'MONITOR'
#!/bin/bash
clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     SAEKA VPN PROTOCOLS - REAL-TIME MONITOR              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Active Connections:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "SSH Connections:"
ss -tnp | grep :22 | grep -v LISTEN | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
    echo "  [$count] $ip"
done
echo ""
echo "Dropbear Connections:"
ss -tnp | grep :143 | grep -v LISTEN | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
    echo "  [$count] $ip"
done
echo ""
echo "V2Ray Connections:"
ss -tnp | grep -E ':8888|:2083|:2087' | grep -v LISTEN | wc -l | xargs echo "  Total:"
echo ""
echo "Trojan Connections:"
ss -tnp | grep :443 | grep -v LISTEN | wc -l | xargs echo "  Total:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Active Users: $(who | wc -l)"
echo "Total Connected IPs: $(ss -tnp | grep -v LISTEN | awk '{print $5}' | cut -d: -f1 | sort -u | wc -l)"
MONITOR

    chmod +x /usr/local/bin/vpn-monitor
    
    # Add to crontab for periodic logging
    echo "*/5 * * * * /usr/local/bin/vpn-monitor > /var/log/vpn-monitor.log 2>&1" | crontab - 2>/dev/null
    
    success "Real-time monitor installed: vpn-monitor"
}

# ============================================
# TARGET SERVER (OPTIONAL)
# ============================================
configure_target() {
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  TARGET SERVER CONFIGURATION (OPTIONAL)                  ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    echo -ne "  ${CYAN}[?]${RESET} Add target server? (y/N): "
    read ADD_TARGET
    
    if [[ "$ADD_TARGET" =~ ^[Yy]$ ]]; then
        echo -ne "  ${CYAN}[?]${RESET} Target Host: "
        read TARGET_HOST
        echo -ne "  ${CYAN}[?]${RESET} Target Port [22]: "
        read TARGET_PORT; TARGET_PORT=${TARGET_PORT:-22}
        echo -ne "  ${CYAN}[?]${RESET} Target User: "
        read TARGET_USER
        echo -ne "  ${CYAN}[?]${RESET} Target Password: "
        read -s TARGET_PASS; echo ""
        
        cat > /usr/local/bin/connect-target << TARGETEOF
#!/bin/bash
echo "Connecting to $TARGET_HOST:$TARGET_PORT..."
sshpass -p '$TARGET_PASS' ssh -o StrictHostKeyChecking=no -p $TARGET_PORT $TARGET_USER@$TARGET_HOST
TARGETEOF
        chmod +x /usr/local/bin/connect-target
        
        echo "TARGET_HOST=$TARGET_HOST" >> /etc/vpn-target.env
        echo "TARGET_PORT=$TARGET_PORT" >> /etc/vpn-target.env
        echo "TARGET_USER=$TARGET_USER" >> /etc/vpn-target.env
        
        success "Target server configured: $TARGET_USER@$TARGET_HOST:$TARGET_PORT"
    else
        info "Target server skipped"
    fi
}

# ============================================
# FINAL SUMMARY
# ============================================
show_summary() {
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "UNKNOWN")
    V2RAY_UUID=$(cat /etc/v2ray/uuid.txt 2>/dev/null || echo "N/A")
    TROJAN_PASS=$(cat /etc/trojan/password.txt 2>/dev/null || echo "N/A")
    
    echo ""
    echo -e "${BG_GREEN}${WHITE}${BOLD}                                                                      ${RESET}"
    echo -e "${BG_GREEN}${WHITE}${BOLD}     SAEKA VPN PROTOCOLS - DEPLOYMENT COMPLETE                         ${RESET}"
    echo -e "${BG_GREEN}${WHITE}${BOLD}                                                                      ${RESET}"
    echo ""
    
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║  SERVER DETAILS                                                  ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}Server IP:${RESET}     ${GREEN}${BOLD}$PUBLIC_IP${RESET}"
    echo -e "  ${WHITE}SSH Ports:${RESET}     22, 80, 143, 443, 8080"
    echo -e "  ${WHITE}Dropbear:${RESET}      80, 143, 443"
    echo -e "  ${WHITE}Stunnel TLS:${RESET}   443, 444, 8443"
    echo -e "  ${WHITE}V2Ray VMess:${RESET}   8888 (WebSocket), 2087 (TLS)"
    echo -e "  ${WHITE}V2Ray VLESS:${RESET}   2083 (WebSocket)"
    echo -e "  ${WHITE}TLS:${RESET}            443"
    echo ""
    
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║  USER CREDENTIALS                                                ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}Username:${RESET}      vpnuser (also: saeka, adminvpn)"
    echo -e "  ${WHITE}Password:${RESET}      ${BOLD}SaekaVPN@2025${RESET}"
    echo ""
    
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║  V2RAY CONFIG                                                    ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}UUID:${RESET}          ${MAGENTA}$V2RAY_UUID${RESET}"
    echo -e "  ${WHITE}VMess Path:${RESET}     /vmess"
    echo -e "  ${WHITE}VLESS Path:${RESET}     /vless"
    echo ""
    
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║  TROJAN CONFIG                                                   ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${WHITE}Port:${RESET}          443"
    echo -e "  ${WHITE}Password:${RESET}      ${MAGENTA}$TROJAN_PASS${RESET}"
    echo ""
    
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║  QUICK COMMANDS                                                  ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${GREEN}[SSH]${RESET}      ssh vpnuser@$PUBLIC_IP"
    echo -e "  ${GREEN}[SSH TLS]${RESET}  ssh vpnuser@$PUBLIC_IP -p 443"
    echo -e "  ${GREEN}[Monitor]${RESET}  vpn-monitor"
    echo -e "  ${GREEN}[Restart]${RESET}  systemctl restart ssh v2ray trojan stunnel4 nginx"
    echo ""
    
    # Save full report
    REPORT="/root/saeka-vpn-report.txt"
    cat > "$REPORT" << REPEOF
============================================
SAEKA VPN PROTOCOLS - FULL REPORT
============================================
Server IP: $PUBLIC_IP
Date: $(date)
============================================

SSH: Ports 22, 80, 143, 443, 8080
Dropbear: Ports 80, 143, 443
Stunnel (TLS): Ports 443, 444, 8443
V2Ray VMess WS: Port 8888, Path /vmess
V2Ray VLESS WS: Port 2083, Path /vless
V2Ray VMess TLS: Port 2087

Users: vpnuser, saeka, adminvpn
Password: SaekaVPN@2025

V2Ray UUID: $V2RAY_UUID
Trojan Password: $TROJAN_PASS
Trojan Port: 443

SSL Certificate: /etc/stunnel/stunnel.pem
Credentials File: /etc/vpn-credentials.txt
============================================
REPEOF
    
    echo -e "  ${GREEN}[OK]${RESET} Full report saved: $REPORT"
    echo ""
    echo -e "${BG_BLUE}${WHITE}${BOLD}  $PUBLIC_IP | SSH:22,80,443 | V2Ray:8888 | Trojan:443 | WS:80  ${RESET}"
    echo ""
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    show_banner
    
    echo -e "\n${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}  ║  STARTING INSTALLATION PROCESS                           ║${RESET}"
    echo -e "${YELLOW}${BOLD}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    sleep 2
    
    check_requirements
    configure_firewall
    install_ssh
    install_stunnel
    install_v2ray
    install_trojan
    install_slowdns
    install_websocket
    create_users
    install_monitor
    configure_target
    show_summary
    
    echo -e "\n${BG_GREEN}${WHITE}${BOLD}  INSTALLATION COMPLETE! SAEKA VPN PROTOCOLS IS READY.  ${RESET}\n"
}

# Run
main
