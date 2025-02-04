# DSS ACME DNS Plugin

This plugin enables automated DNS validation with [acme.sh](https://github.com/acmesh-official/acme.sh) using the DSS API. It supports both standalone acme.sh installations and Proxmox VE's ACME integration.

## Requirements

- Linux-based operating system
- `curl` and `jq` for API interactions
- Root access for installation
- DSS API key

## Installation

Quick install using curl:
```bash
curl -s https://raw.githubusercontent.com/digitalservicesstephan/scripts/main/acme/installer.sh | sudo bash
```

Or download and run the installer manually:
```bash
curl -O https://raw.githubusercontent.com/digitalservicesstephan/scripts/main/acme/installer.sh
chmod +x installer.sh
sudo ./installer.sh
```

The installer will:
1. Detect your environment (Proxmox VE or standard acme.sh)
2. Install required dependencies
3. Download and install the DNS API plugin
4. Configure your API credentials

### Proxmox VE Installation

When installed on Proxmox VE, the plugin will be available in the web interface under "DNS Plugin" when configuring ACME. The plugin will be installed to `/usr/share/proxmox-acme/dnsapi` and credentials will be stored in `/etc/proxmox-acme/dss_credentials.sh`.

### Standard acme.sh Installation

For standard installations, the plugin will be installed to acme.sh's dnsapi directory. You can then use it with acme.sh commands:

```bash
acme.sh --issue -d example.com --dns dns_dss
```

## Configuration

The only required configuration is your DSS API key. The installer will prompt you for this during installation.

## Usage

### With Proxmox VE

1. Go to Datacenter → ACME
2. Add a new ACME account if you haven't already
3. Add a new domain
4. Select "DNS" as the challenge type
5. Select "DSS DNS" as the plugin
6. Save and start the challenge

### With acme.sh

Issue a certificate:
```bash
acme.sh --issue -d example.com --dns dns_dss
```

The plugin will automatically:
1. Create required TXT records
2. Wait for DNS propagation
3. Complete the ACME challenge
4. Remove the TXT records

## Support

For issues or questions, please contact Digital Services Stephan support or open an issue in the repository.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. The MIT License is a permissive license that allows for free use, modification, and distribution of the software, while providing liability protection for the authors.
