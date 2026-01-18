# Deploy Bash

**Deploy Bash** is a lightweight, ultra fast, interactive, and extensible Bash script designed to **automate code deployments** across multiple servers.
It is built for **Debian-based systems** and maintained by **Buffer Punk**.

---

## Overview

`deploy.sh` simplifies deployment workflows by handling tasks like:

* Packaging and deploying your project to multiple remote servers
* Running remote setup commands (on first deploy or updates)
* Managing symlinks for version control (via `current` → latest version)
* Supporting both **domain** and **IP-based** deployments
* Handling **rollbacks** to previous versions
* Restarting specified **systemd services**
* Interactive countdowns and safety prompts

The goal: **make deployment effortless, safe, and repeatable** — without requiring heavy CI/CD tooling.

---

## Features

✅ Deploy to one or multiple servers at once  
✅ Supports both IPs and domain names  
✅ Optional pre-deploy and setup commands  
✅ Built-in rollback mechanism  
✅ NPM install support for node projects  
✅ apt update support (so you don't manually run it)  
✅ Keeps only a specified number of releases (`--keep`)  
✅ Validates configuration and inputs  
✅ Interactive countdown before deploy  
✅ Optionally adds itself to `$PATH` for one-line use (`deploy [options]`)  
✅ Uses human-readable color-coded outputs  

---

## Requirements

* **Debian-based OS** (Ubuntu, Debian, etc.)
* `ssh` access to target servers
* `bash`, `sudo`, and `scp` available
* `dnsutils` (for domain validation)
* Remote servers must support `systemctl`

---

## Installation

```bash
git clone https://github.com/bufferpunk/deploy-bash.git
cd deploy-bash
chmod +x deploy.sh
./deploy.sh
```

The first run will ask if you want to add it to your `$PATH`:

```bash
Do you want to add it to your $PATH? (y/n)
```

If you choose “y”, it’ll create a symlink at `/usr/local/bin/deploy`, so you can run it globally:

```bash
deploy [options]
```

---

## Usage

You can deploy with flags or a configuration file.

### **Option 1: Using flags**

```bash
deploy \
  --project=myapp \
  --type=ip \
  --servers=[192.168.1.2,192.168.1.3] \
  --services=[nginx,myapp.service] \
  --deploy-dir=/var/www \
  --setup=full
  --apt-update
```

### **Option 2: Using a config file**

Create a config file (e.g. `prod.conf`):

```bash
SERVERS=[192.168.1.2,192.168.1.3]
SERVICES=[nginx,myapp.service]
TYPE="ip"
PROJECT_NAME="myapp"
DEPLOY_DIR="/var/www"
SSH_USER="ubuntu"
SSH_KEY="~/.ssh/id_rsa"
NODE_HOME="." # use relative paths
SETUP_COMMAND="echo something"
# etc ...
```

Then deploy with:

```bash
deploy --config=deployment/prod.conf
```

---

## Rollback Example

If something goes wrong, rollback to an earlier version:

```bash
deploy --rollback=2 --config=prod.conf
```

This restores the second-most recent version and restarts your services.

---

## Setup Commands

The `--setup` flag allows running arbitrary setup commands on remote servers.

* `--setup=full`: deploys and then runs setup
* `--setup=only`: runs setup without deploying

You’ll be asked interactively how many setup commands you want to add, for example:

```
How many commands do you want to run on the remote server(s)?: 2
Enter command 1: apt update -y
Enter command 2: systemctl restart nginx
```

---

## Keeping Versions

The script automatically archives deployed versions and keeps a maximum number of them (default `5`).
Use `--keep=<number>` to change that limit.

---

## Example Deployment Flow

```bash
deploy --config=deployment/deploy.conf --npm
```

Output (simplified):

<img width="1187" height="354" alt="image" src="https://github.com/user-attachments/assets/25980bad-f895-4e73-b7ed-8e26400f71ec" />
<img width="1853" height="337" alt="image" src="https://github.com/user-attachments/assets/89420706-9725-4204-b50c-f80e4db6e8a6" />
<img width="1904" height="889" alt="image" src="https://github.com/user-attachments/assets/cd36cbef-4c1b-4a59-a0d6-759aab1220d6" />


---

## Folder Structure Example

```
myapp/
├── deployment/
|   ├── awesome.conf
|   ├── prod.conf
|   └── your.other.scripts
├── versions/
│   ├── myapp20251020142300/
│   ├── myapp20251019115022/
│   └── ...
└── your_other_code
```

---

## Supported Flags

| Flag                   | Description                           |                                 |
| ---------------------- | ------------------------------------- | ------------------------------- |
| `--config=<file>`      | Load configuration from a file        |                                 |
| `--project=<name>`     | Name of the project folder            |                                 |
| `--servers=[a,b,...]`  | Comma-separated server list           |                                 |
| `--services=[a,b,...]` | Comma-separated systemd service names |                                 |
| `--type=<domain / ip>` | Type of server list provided          |                                 |
| `--deploy-dir=<path>`  | Remote directory for deployment       |                                 |
| `--apt-update`         | Run `apt update` on server            |                                 |
| `--npm`                | Run `npm install` on server           |         after deploying         |
| `--setup=<full / only>`| Setup and deploy, or setup only       |                                 |
| `--rollback=<number>`  | Roll back to a previous version       |                                 |
| `--keep=<number>`      | Number of old versions to retain      |                                 |
| `--help` / `-h`        | Show usage                            |                                 |

---

## License

MIT License © 2025 [Buffer Punk](https://github.com/bufferpunk)

---

## Contributing

Pull requests are welcome!
Please open an issue first to discuss proposed changes.
