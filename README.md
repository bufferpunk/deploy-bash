# ⚡ Deploy Bash - Dead Simple, Battle-Tested Bash Deployment Script

**`deploy.sh`** is a high-performance, zero-fluff Bash deployment tool built for developers who like **speed**, **control**, and **clarity**. Tested in real production environments, it's capable of deploying any app to any number of remote servers over SSH, with built-in configuration management, service control, and setup routines.

> 🧪 Tested and used successfully in production on two real-world apps.

---

## 🚀 Features

- ✅ **Domain/IP validation** with optional DNS checks
- ✅ **Auto-setup mode** with support for `npm install`
- ✅ **Service restarts** post-deployment
- ✅ **Remote archiving + versioning**
- ✅ **Colorful and friendly terminal UX**
- ✅ **Safe prompts**, countdown before deployment
- ✅ **Extensible config system**
- ✅ **Self-validating CLI flags**
- ✅ **Failsafe traps** for error handling

---

## 🧠 How It Works

This script automates the end-to-end deployment process for web apps. It does the following:

1. Parses CLI arguments or prompts for project details
2. Validates server IPs/domains
3. Archives the project locally
4. Transfers the archive to remote servers
5. Sets up remote directory structure and services
6. Optionally runs a one-time setup with `npm install`
7. Restarts specified services
8. Keeps versioned archives for rollback safety

---

## 🛠 Usage

```bash
bash deploy.sh [options]
```

### 🔧 Available Options

| Flag | Description |
|------|-------------|
| `--type=domain\|ip`          | Deployment target type |
| `--servers=...`              | Comma-separated list of IPs or domains |
| `--project=name`             | Name of the project to deploy |
| `--config=path/to/file`      | Path to optional `.env` config |
| `--services=...`             | Comma-separated list/array of services to restart |
| `--setup=full\|only`         | Only run setup (no deployment) |
| `--npm`                      | Do `npm install` in setup |
| `--help`                     | Show help |
| `--rollback=number`          | Rollback to a specific version |

---

## ⚙️ Example

```bash
bash deploy.sh \
  --type=ip \
  --servers=[192.168.1.2,192.168.1.3] \
  --project=my-app \
  --services=my-app.service,nginx \
  --setup=full \
  --npm
```

---

## 🌐 Config File

You can pass a `.env` config using `--config=config.env`. Supported variables:

```dotenv
SERVERS="myserver.com,api.myserver.com"
PROJECT_NAME=my-app
SERVICES="my-app.service,nginx" (Not recommended)
DEPLOY_DIR="/var/www/my-app"
LOG_FILE="/var/log/deploy.log"
TYPE="domain"
SETUP_COMMAND="./some/bash/script.sh"
NODE_HOME="./api" (This is where your node app is. Always use a relative path)
```

---

## 🧰 Setup Mode

If you just want to initialize the remote server without deploying code:

```bash
./deploy.sh --servers=[api1.myserver.com,api2.myserver.com] --services=[nginx,mariadb] --setup=full --npm
./deploy.sh --config=deploy.env --setup=full --npm
./deploy.sh --help
# and so on...
```

---

## 🧼 Safety Features

- Countdown before any deployment begins
- Validation of server type, services, and IPs/domains
- Prevents accidental overwrites or misdeployments
- Color-coded output for easy parsing
- Traps any errors and gives meaningful messages

---

## 📦 Versioning & Rollback

The script automatically keeps old versions of your app in `releases/` folder on the remote server. You can manually roll back by extracting an older archive or do:

```bash
  deploy.sh --config=deployment/deploy.conf --services=[nginx] --rollback=3 # Rollback to the 3rd last version
```
This will extract the 3rd last version of the archive in the `releases/` folder and make it the current version.

---

## 🛡️ Requirements

- `bash`
- `scp`, `ssh`
- `tar`
- `host` (auto-installs `dnsutils` if not found)

---

## 📣 Real-World Proven

This script has been tested and successfully used to deploy **two real-world applications** with different services and environments.
One of them is Libly, an open-source project that helps you manage your library. Visit [Libly](https://libly.liny.studio) to check out the project.
The other is a closed-source project, but you can find the live app at [Topically](https://topically.liny.studio).

---

## 💡 Tips

- Link the script to a bin directory in your $PATH for convenience:  
  ```bash
  chmod +x deploy.sh
  sudo ln -s ./deploy.sh /usr/local/bin/deploy
  # You can now run it with just `deploy`. eg: `deploy --help`
  ```
- Add a `deploy.env` file for each project and reuse the script globally.
- Run with `--help` to get a clean usage guide.

---

## ❤️ Author

Made with love by [@Scion-Kin](https://github.com/Scion-Kin)  
> "If you can't automate it, it's not worth doing."

---

## 🏁 License

MIT – do whatever you want, just don't blame me if you rage-deploy to prod 😄

## 🐞 Issues
If you find any bugs or have feature requests, please open an issue on GitHub.

## 📜 Changelog
- **v1.0** - Initial release with core features

## Contributing
Contributions are welcome! Please fork the repo and submit a pull request.

## Disclaimer
This script is provided "as-is" without any warranty. Use at your own risk. Always test in a safe environment before deploying to production.
