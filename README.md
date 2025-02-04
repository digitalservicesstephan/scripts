# DSS Scripts

This repository contains various scripts and tools for automating tasks with the DSS API.

## Contents

### ACME DNS Plugin

Located in the `acme` directory, this plugin enables automated DNS validation with [acme.sh](https://github.com/acmesh-official/acme.sh) using the DSS API. It supports both standalone acme.sh installations and Proxmox VE's ACME integration.

[Learn more about the ACME DNS Plugin](acme/README.md)

## Requirements

Each tool or script may have its own specific requirements. Please refer to the README file in each directory for detailed requirements and setup instructions.

## Quick Start

### Install ACME DNS Plugin
```bash
curl -s https://raw.githubusercontent.com/digitalservicesstephan/scripts/main/acme/installer.sh | sudo bash
```

For manual installation or other tools, navigate to the specific tool's directory and follow the installation instructions in its README file.

## API Endpoint

All scripts in this repository use the DSS API endpoint:
```
https://panel.digitalservicesstephan.de/api/v1
```

## Contributing

If you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues, questions, or feature requests:
- Open an issue in this repository
- Contact Digital Services Stephan support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. The MIT License is a permissive license that allows for free use, modification, and distribution of the software, while providing liability protection for the authors.
