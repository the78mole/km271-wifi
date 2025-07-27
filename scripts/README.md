# Scripts Directory

This directory contains utility scripts for the KM271-WiFi project.

## Available Scripts

### 🔍 `analyze-renovate.sh`

Comprehensive analysis tool for Renovate configuration and dependency coverage.

**Usage:**
```bash
./scripts/analyze-renovate.sh
```

**Features:**
- Scans project for all dependency types (Python, Docker, firmware)
- Analyzes current Renovate configuration coverage
- Tests regex patterns for custom managers
- Provides recommendations for improving dependency management
- Shows detailed summary of monitored dependencies

**Output includes:**
- Docker images from GitLab CI and DevContainer
- ESPHome configuration files
- Renovate manager coverage analysis
- Coverage statistics

*Note: Python dependencies and firmware version management have been moved to separate projects and are no longer tracked here.*

### 📦 `update_firmwares.py`

*(Currently empty - placeholder for future firmware update automation)*

## Project Dependencies Covered

ℹ️ **Python Dependencies** 
- Moved to separate project
- No longer tracked in this repository

✅ **Docker Images** 
- GitLab CI: `texlive/texlive:latest-full`
- DevContainer: `ghcr.io/the78mole/kicaddev-docker:latest`

ℹ️ **Firmware Versions** 
- Moved to separate firmware management project
- No longer tracked in this repository

## Renovate Configuration

The project uses Renovate for automated dependency updates with:
- Grouped updates by dependency type
- DevContainer image monitoring  
- Dependency dashboard with German timezone
- Simplified configuration focused on core dependencies
