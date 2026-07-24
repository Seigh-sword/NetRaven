# Contributing to NetRaven

Thank you for your interest in contributing to NetRaven! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Bugs

- Use the GitHub issue tracker
- Describe the issue clearly with steps to reproduce
- Include your environment details (OS, bash version, tool versions)
- Attach relevant logs or screenshots

### Suggesting Features

- Open a GitHub issue with the tag `enhancement`
- Describe the feature and its use case
- Explain why it would be useful for ethical hacking workflows

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes on Kali Linux
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Coding Standards

- Use Bash strict mode where possible (`set -euo pipefail`)
- Follow existing code style and naming conventions
- Add comments for complex logic
- Ensure all tools used are available in Kali Linux repositories
- Test all scripts with `bash -n` before committing

### Adding New Modules

- Place module files in `src/modules/`
- Source `src/core/config.sh` and `src/core/utils.sh`
- Use the color variables defined in config
- Save all output to `$RESULTS_DIR/<module>/`
- Add the module to the main menu in `netraven.sh`

## Development Setup

```bash
git clone https://github.com/Seigh-sword/NetRaven.git
cd netraven
bash -n src/core/*.sh
bash -n src/modules/*.sh
```

## Questions?

Open an issue or reach out via GitHub Discussions.
