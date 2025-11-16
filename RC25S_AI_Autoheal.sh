#!/bin/bash
# ============================================================
# 🤖 RC25S AI AUTOHEAL + HEALTH MONITOR SYSTEM (v2.0)
# Author: GPT-5
# ============================================================

LOGFILE="/var/log/rc25s-autoheal-ai.log"
REPO_DIR="/srv/repo/vibecoding"
APP_DIR="$REPO_DIR/rc25s_dashboard_app"
FRONTEND_DIR="$APP_DIR/rc25s_frontend"
SERVICE_NAME="rc25s-dashboard.service"
HEALTH_URL="http://127.0.0.1:4545/health"
LLM_URL="http://127.0.0.1:4545/llm"

log() { echo "$(date +%F
