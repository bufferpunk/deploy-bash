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
| `--type=domain|ip`     | Deployment target type |
| `--servers=...`        | Comma-separated list of IPs or domains |
| `--project=name`       | Name of the project to deploy |
| `--config=path`        | Path to optional `.env` config |
| `--services=...`       | Comma-separated list of services to restart |
| `--setup=only`         | Only run setup (no deployment) |
| `--npm=false`          | Skip `npm install` in setup |
| `--help`               | Show help |

---

## ⚙️ Example

```bash
bash deploy.sh \
  --type=ip \
  --servers=192.168.1.2,192.168.1.3 \
  --project=my-app \
  --services=my-app.service,nginx \
  --setup=only \
  --npm=true
```

---

## 🌐 Config File

You can pass a `.env` config using `--config=config.env`. Supported variables:

```dotenv
type=domain
servers=myserver.com,api.myserver.com
project=my-app
services=my-app.service,nginx
setup=only
npm=true
```

---

## 🧰 Setup Mode

If you just want to initialize the remote server without deploying code:

```bash
bash deploy.sh --setup=only --npm=false
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

The script automatically keeps old versions of your app in `versions/` on the remote server. You can manually roll back by extracting an older archive.

> 🎯 Coming soon: a built-in rollback command

---

## 🛡️ Requirements

- `bash`
- `scp`, `ssh`
- `tar`
- `host` (auto-installs `dnsutils` if not found)

---

## 📣 Real-World Proven

This script has been tested and successfully used to deploy **two real-world applications** with different services and environments.

---

## 💡 Tips

- Alias the script for convenience:  
  ```bash
  alias deploy="bash /path/to/deploy.sh"
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
