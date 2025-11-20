# Deployment Guide
## Google Intelligent Group Multi-Agent System

This guide provides step-by-step instructions for deploying the Google Intelligent Group Multi-Agent System to production.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Deployment](#backend-deployment)
3. [Frontend Deployment](#frontend-deployment)
4. [Fonoster Server Deployment](#fonoster-server-deployment)
5. [Environment Configuration](#environment-configuration)
6. [Production Checklist](#production-checklist)

---

## Prerequisites

### Required Services
- **AWS EC2** instance (or similar cloud server)
- **Domain name** (optional, for custom URL)
- **SSL Certificate** (for HTTPS)
- **Git** access to repository

### Required Accounts & API Keys
- **Google Gemini API Key** (for LLM)
- **Google Maps API Key** (for GoogleMap Agent)
- **Fonoster** credentials (for Telephone Agent)

---

## Backend Deployment

### Step 1: Server Setup

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.11+
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Step 2: Clone Repository

```bash
# Clone the repository
cd /home/ubuntu
git clone https://github.com/chakradharkalle03-arch/google-intelligent-group.git
cd google-intelligent-group/backend
```

### Step 3: Setup Python Environment

```bash
# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

```bash
# Create .env file
nano .env
```

Add the following:
```env
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
FONOSTER_SERVER_URL=http://localhost:3001
```

### Step 5: Setup Process Manager (PM2 or systemd)

#### Option A: Using PM2 (Recommended)

```bash
# Install PM2
npm install -g pm2

# Create PM2 ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'google-intelligent-backend',
    script: 'main.py',
    interpreter: 'venv/bin/python',
    cwd: '/home/ubuntu/google-intelligent-group/backend',
    env: {
      NODE_ENV: 'production'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
}
EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### Option B: Using systemd

```bash
# Create systemd service
sudo nano /etc/systemd/system/google-intelligent-backend.service
```

Add:
```ini
[Unit]
Description=Google Intelligent Group Backend API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/google-intelligent-group/backend
Environment="PATH=/home/ubuntu/google-intelligent-group/backend/venv/bin"
ExecStart=/home/ubuntu/google-intelligent-group/backend/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable google-intelligent-backend
sudo systemctl start google-intelligent-backend
```

### Step 6: Setup Reverse Proxy (Nginx)

```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/google-intelligent-backend
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # For SSE streaming
        proxy_buffering off;
        proxy_cache off;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/google-intelligent-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 7: Setup SSL (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

---

## Frontend Deployment

### Step 1: Build Frontend

```bash
cd /home/ubuntu/google-intelligent-group/frontend

# Install dependencies
npm install

# Build for production
npm run build
```

### Step 2: Setup Next.js with PM2

```bash
# Create PM2 config for frontend
cat > ecosystem-frontend.config.js << EOF
module.exports = {
  apps: [{
    name: 'google-intelligent-frontend',
    script: 'node_modules/next/dist/bin/next',
    args: 'start',
    cwd: '/home/ubuntu/google-intelligent-group/frontend',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      NEXT_PUBLIC_API_URL: 'https://your-domain.com'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
}
EOF

# Start frontend
pm2 start ecosystem-frontend.config.js
pm2 save
```

### Step 3: Configure Nginx for Frontend

```bash
sudo nano /etc/nginx/sites-available/google-intelligent-frontend
```

Add:
```nginx
server {
    listen 80;
    server_name your-frontend-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Fonoster Server Deployment

### Step 1: Install Fonoster

```bash
# Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Fonoster
npm install -g @fonoster/fonoster
```

### Step 2: Configure Fonoster

```bash
# Create Fonoster configuration directory
mkdir -p ~/.fonoster
nano ~/.fonoster/config.json
```

### Step 3: Start Fonoster Service

```bash
# Create PM2 config for Fonoster
pm2 start fonoster --name fonoster-server
pm2 save
```

---

## Environment Configuration

### Backend Environment Variables

Create `/home/ubuntu/google-intelligent-group/backend/.env`:

```env
# Gemini API
GEMINI_API_KEY=your_gemini_api_key_here

# Google Maps API
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Fonoster Configuration
FONOSTER_SERVER_URL=http://localhost:3001
FONOSTER_ACCESS_KEY_ID=your_access_key
FONOSTER_ACCESS_KEY_SECRET=your_secret_key

# Server Configuration
HOST=0.0.0.0
PORT=8000
ENVIRONMENT=production
```

### Frontend Environment Variables

Create `/home/ubuntu/google-intelligent-group/frontend/.env.production`:

```env
NEXT_PUBLIC_API_URL=https://your-backend-domain.com
```

---

## Production Checklist

### Security
- [ ] SSL certificates installed and auto-renewal configured
- [ ] API keys stored securely in environment variables
- [ ] Firewall configured (only allow ports 80, 443, 22)
- [ ] Regular security updates enabled
- [ ] CORS configured properly in backend

### Monitoring
- [ ] PM2 monitoring set up
- [ ] Log rotation configured
- [ ] Error tracking (optional: Sentry)
- [ ] Uptime monitoring (optional: UptimeRobot)

### Backup
- [ ] Database backups (if using database)
- [ ] Configuration files backed up
- [ ] Environment variables documented securely

### Performance
- [ ] Nginx caching configured (if needed)
- [ ] CDN setup for static assets (optional)
- [ ] Load balancing (if scaling)

---

## Troubleshooting

### Backend Not Starting
```bash
# Check logs
pm2 logs google-intelligent-backend
# or
sudo journalctl -u google-intelligent-backend -f

# Check if port is in use
sudo netstat -tulpn | grep 8000
```

### Frontend Not Starting
```bash
# Check logs
pm2 logs google-intelligent-frontend

# Rebuild if needed
cd frontend
npm run build
pm2 restart google-intelligent-frontend
```

### Nginx Issues
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

---

## Quick Start Commands

```bash
# Start all services
pm2 start all

# Stop all services
pm2 stop all

# Restart all services
pm2 restart all

# View logs
pm2 logs

# Monitor
pm2 monit
```

---

## Support

For issues or questions, refer to:
- Repository: https://github.com/chakradharkalle03-arch/google-intelligent-group
- Documentation: `/docs` folder
- Agent Code Explanation: `docs/AGENT_CODE_EXPLANATION.md`

---

**Last Updated:** November 2025

