# Run Instructions (Beginner Friendly)

This project spins up a complete **CI + Code Quality + Observability** stack with one command.

**Included services**

- **Nginx reverse proxy** (single entry on port 80)
    
- **Gitea** (Git server)
    
- **Jenkins** (CI/CD)
    
- **SonarQube Community** + dedicated Postgres DB
    
- **Docker Registry** (private registry with basic auth)
    
- **Prometheus** + **Grafana**
    
- **cAdvisor** + **node-exporter** for metrics
    

You will also find a **demo app** (`demo-app/`) with a `Jenkinsfile` that:

1. runs tests
    
2. runs SonarQube scan
    
3. builds a Docker image
    
4. pushes to your local registry
    

---

## 0) Requirements (must-have)

### On Linux (recommended)

- Docker Engine
    
- Docker Compose v2 (`docker compose ...` works)
    
- Ports open: **80**, **2222**, **5000** (and optionally others if you expose them)
    

Check:
```
docker --version
docker compose version
```

### System requirements

- **RAM:** 4 GB minimum (8 GB recommended)
    
- **Disk:** a few GB free (images + volumes)
    

### SonarQube host setting (important)

SonarQube’s Elasticsearch usually needs:

```
sudo sysctl -w vm.max_map_count=262144
```

To make it permanent:

```
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-sonarqube.conf
sudo sysctl --system
```

## 1) Clone and prepare the config

```
git clone <your-repo-url>
cd projects/devops-stack-ci-observability/devops-stack
```

Create your local environment file:

```
cp .env.example .env
```

## 2) Add local DNS entries (so the URLs work)

This stack uses “local domains” like `gitea.local`, `jenkins.local`, etc.

### Option A (simple): edit `/etc/hosts` on your machine

Replace `<SERVER_IP>` with the server IP where Docker runs.


```
sudo nano /etc/hosts
```

Add:
```
<SERVER_IP> gitea.local jenkins.local sonarqube.local grafana.local prometheus.local
```

Example:

```
10.0.0.12 gitea.local jenkins.local sonarqube.local grafana.local prometheus.local
```

## 3) Start everything (recommended path)

### One-command bootstrap

Run:

```
./scripts/bootstrap.sh
```

This should:

1. load `.env`
    
2. generate Docker Registry auth file (`registry/auth/htpasswd`)
    
3. start all containers (`docker compose up -d`)
    
4. print the URLs
    

If everything is OK, you can open:

- Gitea: `http://gitea.local`
    
- Jenkins: `http://jenkins.local`
    
- SonarQube: `http://sonarqube.local`
    
- Grafana: `http://grafana.local`
    
- Prometheus: `http://prometheus.local`
    

 **Important:** SonarQube can take 1–3 minutes the first time.  
If you see a temporary `502 Bad Gateway`, wait a bit and refresh.

---

## 4) First-run checklist (UI setup)

### A) Gitea (create org/users/repo)

Open: `http://gitea.local`

1. Login with the admin credentials from `.env` / `.env.example`
    
2. Create an **Organization** (example: `acme`)
    
3. Create demo users:
    
    - `dev1` (developer)
        
    - `ci-bot` (used by Jenkins)
        
4. Create repo inside org:
    
    - `acme/demo-app`
        
5. Push the demo app from the `demo-app/` directory (see step 5 below)
    

---

### B) SonarQube (create token for Jenkins)

Open: `http://sonarqube.local`

1. Login as admin
    
2. Top-right avatar → **My Account**
    
3. **Security** tab → Tokens
    
4. Create token named `jenkins`
    
5. Token type:
    
    - Choose **User Token** (best for this project)
        
6. Copy token (you will paste it into Jenkins credentials)
    

---

### C) Jenkins (add credentials + create pipeline)

Open: `http://jenkins.local`

1. Login as Jenkins admin (from `.env` / setup wizard)
    
2. Go: **Manage Jenkins → Credentials → (System) → Global → Add Credentials**
    

Add these credentials:

#### 1) Gitea access (ci-bot)

- Kind: **Username with password**
    
- Username: `ci-bot`
    
- Password: `<ci-bot password>`
    
- ID: `GITEA_CI_BOT`
    

#### 2) Sonar token

- Kind: **Secret text**
    
- Secret: `<token from SonarQube>`
    
- ID: `SONAR_TOKEN`
    

#### 3) Registry creds

- Kind: **Username with password**
    
- Username: `registryuser`
    
- Password: `<registry password>`
    
- ID: `REGISTRY_CREDS`
    

Now create a pipeline job:

1. Jenkins → **New Item**
    
2. Name: `demo-app-pipeline`
    
3. Type: **Pipeline**
    
4. In Pipeline section:
    
    - Definition: **Pipeline script from SCM**
        
    - SCM: **Git**
        
    - Repo URL (inside docker network):  
        `http://gitea:3000/acme/demo-app.git`
        
    - Credentials: **GITEA_CI_BOT**
        
    - Branch: `*/main`
        
    - Script path: `Jenkinsfile`
        
5. Save → **Build Now**
    

---

## 5) Push the demo app to Gitea

From the demo app folder (adjust path if needed):

```
cd demo-app
git init
git add .
git commit -m "Initial demo app"
git branch -M main
git remote add origin http://gitea.local/acme/demo-app.git
git push -u origin main
```

If it asks for username/password:

- use `dev1` credentials (or your admin if repo permissions require it)
    

Once pushed, run the Jenkins pipeline again.

---

## 6) Verify it worked (what to check)

### Jenkins

- Build is green
    
- Stages show something like:
    
    - **Test → SonarQube Scan → Build & Push**
        

### SonarQube

Open `http://sonarqube.local` → Projects:

- `demo-app` exists
    
- shows analysis results
    

### Registry (confirm your image exists)

On the Docker host:

```
curl -u registryuser:<REGISTRY_PASSWORD> http://<SERVER_IP>:5000/v2/_catalog
curl -u registryuser:<REGISTRY_PASSWORD> http://<SERVER_IP>:5000/v2/demo-app/tags/list
```

### Grafana/Prometheus

- Prometheus targets: `http://prometheus.local/targets` → all UP
    
- Grafana dashboards show metrics (Node exporter + cAdvisor)
    

---

## 7) Run the demo app image (from registry)

After Jenkins pushes the image, pull and run it:

```
docker login <SERVER_IP>:5000
docker pull <SERVER_IP>:5000/demo-app:latest
docker run -d --name demo-app -p 3000:3000 <SERVER_IP>:5000/demo-app:latest
```

Then open:

- `http://<SERVER_IP>:3000`
    

(If your app uses another port, check `demo-app/Dockerfile`.)

---

# Stop / Start / Reset (important)

## Stop everything (keep data)

```
docker compose stop
```

## Start again (keep data)
```
docker compose start
```

## Shut down everything (keep data)

```
docker compose down
```

## FULL RESET (delete all data, clean slate)

Use this if passwords don’t match `.env` anymore, or you want “fresh install”:

```
docker compose down -v --remove-orphans
```

Then rerun:

```
./scripts/bootstrap.sh
```

# Common Problems + Fixes (the pitfalls we hit)

### 1) “I changed `.env` but logins didn’t change”

That’s expected. Passwords are stored in volumes after first-run.  
Fix: `docker compose down -v --remove-orphans` and start fresh.

### 2) Registry auth fails with “unbound variable”

Your script expects a variable name that doesn’t exist (example: `REGISTRY_PASSWORD` vs `REGISTRY_PASS`).  
Fix: ensure `.env.example` and scripts use the same variable name.

### 3) SonarQube shows 502 / STARTING

Normal on first boot (DB migrations + ES warmup).  
Wait 1–3 minutes and refresh.

### 4) SonarQube fails due to `vm.max_map_count`

Fix: set `vm.max_map_count=262144` (see Requirements section).