# Plugins

This directory is for **plugin directories** used by the [agentget](https://github.com/joeyism/agentget)
framework.

## Expected Pattern

```
plugins/<plugin-name>/
```

Each subdirectory is expanded recursively by agentget. Contents are
plugin-specific.

## Example

```
plugins/
├── custom-tool/
│   ├── plugin.yaml
│   └── src/
└── report-generator/
    ├── config.json
    └── templates/
```

## Usage

Agentget auto-discovers plugin directories from this path when the repo is added
as a source.
