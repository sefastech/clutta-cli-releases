# Clutta CLI Releases

Welcome to the **Clutta CLI Releases** repository! This repository serves as a central hub for hosting and distributing the compiled binaries of the Clutta CLI tool. These binaries are designed to work seamlessly across multiple platforms, enabling developers to interact with the Clutta ecosystem from the command line.

## About

This repository does **not contain any source code**. It exists solely to provide the latest and historical releases of the **Clutta CLI tool**. Developers can download these precompiled binaries and use them directly or build language-specific wrappers (e.g., for Java, Python, Go) that integrate with the Clutta CLI tool.

## Available Platforms

The CLI binaries are available for the following platforms:

- **Linux**
  - `amd64`
  - `arm64`
- **macOS**
  - `amd64`
  - `arm64`
- **Windows**
  - `amd64`
  - `arm64`

Each binary is optimized for performance and security.

## Installation

### macOS & Linux
To install Clutta CLI, run the following command:

```bash
curl -L https://raw.githubusercontent.com/sefastech/clutta-cli-releases/main/scripts/install-clutta.sh | bash
```

To install a specific version, use:

```bash
curl -L https://raw.githubusercontent.com/sefastech/clutta-cli-releases/main/scripts/install-clutta.sh | bash -s -- -v v1.0.0
```

### Windows
Run the following PowerShell command:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sefastech/clutta-cli-releases/main/scripts/install-clutta.bat" -OutFile "install-clutta.bat"
.\install-clutta.bat
```

To install a specific version, use:

```powershell
.\install-clutta.bat -v v1.0.0
```

## Downloading Binaries Manually

If you prefer to download binaries manually, visit the **[Releases](https://github.com/sefastech/clutta-cli-releases/releases)** page and choose the appropriate version for your OS and architecture.

## Usage

After installation, verify the installation by running:

```bash
clutta --version
```

### Features
- Query system status
- Send pulses and manage Clutta objects
- Perform CRUD operations against Clutta endpoints

Refer to the official Clutta documentation for detailed usage instructions.

## Language-Specific Wrappers

Several repositories extend this repository to provide language-specific wrappers:

- [Go Wrapper](https://github.com/sefastech/clutta-go)
- [Python Wrapper](https://github.com/sefastech/clutta-python)
- [Java Wrapper](https://github.com/sefastech/clutta-java)

If you'd like to contribute a new wrapper, feel free to fork a relevant repository and open a pull request.

## License

The Clutta CLI binaries are distributed under a **proprietary license**. Usage is subject to the terms outlined in the Clutta Terms of Service.

## Contributing

This repository is only for hosting binaries. If you encounter issues with the CLI tool itself, please report them in the main Clutta repository.

## Support

For any issues or questions regarding the CLI tool or its usage, please open an issue in the respective wrapper repository or contact **support@clutta.io**.

Stay productive, stay seamless. **Happy Clutta-ing!** 🚀