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

### 🎯 `test-renovate-coverage.sh`

Final coverage test script that validates what dependencies Renovate will actually monitor.

**Usage:**
```bash
./scripts/test-renovate-coverage.sh
```

**Features:**
- Shows final overview of all monitored dependencies
- Validates coverage for Python dependencies (pyproject.toml)
- Checks Docker image monitoring (GitLab CI and DevContainer)
- Verifies firmware version tracking
- Provides coverage summary and statistics

## Project Dependencies Covered

✅ **Python Dependencies** 
- Managed via pyproject.toml
- Monitored by Renovate pip_setup manager

✅ **Docker Images** 
- GitLab CI: `texlive/texlive:latest-full`
- DevContainer: `ghcr.io/the78mole/kicaddev-docker:latest`
- Monitored by Renovate dockerfile and devcontainer managers

✅ **Firmware Versions** 
- ESP Buderus KM271 firmware from dewenni/ESP_Buderus_KM271
- Monitored via Renovate regex manager from sources.yaml

## Renovate Configuration

The project uses Renovate for automated dependency updates with:
- Grouped updates by dependency type
- DevContainer image monitoring  
- Python dependency management via pyproject.toml
- Firmware version tracking via regex patterns
- Dependency dashboard with German timezone
- Comprehensive coverage of all project dependencies

## Usage

To analyze the current Renovate coverage, run both scripts in sequence:

```bash
# Full analysis of project dependencies and Renovate configuration
./scripts/analyze-renovate.sh

# Final coverage validation  
./scripts/test-renovate-coverage.sh
```

These scripts help ensure that all project dependencies are properly monitored by Renovate for automated updates.
