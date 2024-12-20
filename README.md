# Clutta CLI Releases

Welcome to the **Clutta CLI Releases** repository! This repository serves as a central hub for hosting and distributing the compiled binaries of the Clutta CLI tool. These binaries are designed to work seamlessly across multiple platforms, enabling developers to interact with the Clutta ecosystem from the command line.

## About

This repository does **not contain any source code**. It exists solely to provide the latest and historical releases of the Clutta CLI tool. Developers can download these precompiled binaries and use them directly or build language-specific wrappers (e.g., for Java, Python, Go) that integrate with the Clutta CLI tool.

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

Each binary is optimized and obfuscated to ensure performance and security.

## How to Download

To download the appropriate binary for your platform, navigate to the [Releases](https://github.com/sefastech/clutta-cli-releases/releases) page and select the desired version.

### Example:

For Linux (amd64):
```bash
curl -LO  https://github.com/sefastech/clutta-cli-releases/releases/download/vX.Y.Z/clutta-cli_linux_amd64
chmod +x clutta-cli_linux_amd64
./clutta-cli_linux_amd64 --help
```

For Windows
```bash
Invoke-WebRequest -Uri  https://github.com/sefastech/clutta-cli-releases/releases/download/vX.Y.Z/clutta-cli_windows_amd64.exe -OutFile clutta-cli_windows_amd64.exe
.\clutta-cli_windows_amd64.exe --help
```
Replace vX.Y.Z with the specific version you wish to download.


### Using the CLI Tool
The CLI tool enables seamless interaction with the Clutta ecosystem, including:

### Sending pulses and Managing Clutta objects
- Querying system status
- Performing CRUD operations against Clutta endpoints
- Refer to the documentation provided by your integration library for detailed usage instructions.

### Language-Specific Wrappers
Several repositories use this repository as a source for building language-specific wrappers around the CLI tool. You can explore or contribute to these wrappers:

[Go Wrapper](https://github.com/sefastech/clutta-go)
[Python Wrapper](https://github.com/sefastech/clutta-python)
[Java Wrapper](https://github.com/sefastech/clutta-java)


If you'd like to contribute a new wrapper for another language, feel free to fork the relevant repository and open a pull request.

### License
The Clutta CLI binaries are distributed under a proprietary license. Usage is subject to the terms outlined in the Clutta Terms of Service.

### Support
For any issues or questions regarding the CLI tool or its usage, please open an issue in the respective wrapper repository or contact support@clutta.io

Stay productive, stay seamless. Happy Clutta-ing! 🚀
