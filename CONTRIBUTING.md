# Contributing to KM271-WiFi

Thank you for your interest in contributing to the KM271-WiFi project! This document provides guidelines for contributing to this open hardware project.

## 🎯 Project Overview

KM271-WiFi is a WiFi-enabled replacement for the Buderus KM271 module, designed to control Buderus heating systems with Logamatic 2107 controllers. The project is released under the **TAPR Open Hardware License** Version 1.0.

## 🤝 Ways to Contribute

### 1. Hardware Development
- **PCB Design Improvements**: Help fix known issues (e.g., I2C pull-up bug)
- **Extensions**: Create add-on boards (like the Ethernet extension)
- **3D Models**: Design and share enclosures or mounting solutions
- **Manufacturing Files**: Improve Gerber files, pick-and-place data

### 2. Documentation
- **Hardware Documentation**: Update schematics, improve assembly guides
- **Getting Started Guides**: Help new users with installation and setup
- **Translations**: Translate documentation to other languages
- **Interactive BOM**: Maintain and improve the interactive bill of materials

### 3. Firmware & Software
- **ESPHome Configurations**: Share and improve YAML configurations
- **Custom Components**: Develop ESPHome components (e.g., I2C-OneWire bridge support)
- **Scripts**: Improve automation scripts for dependency management

### 4. Testing & Validation
- **Hardware Testing**: Test the board with different Buderus controllers
- **Production Validation**: Report successful hardware production
- **Compatibility Reports**: Test with various heating system configurations

## 📋 How to Contribute

### Reporting Issues
1. **Hardware Issues**: Use the [Hardware Issue template](https://github.com/the78mole/km271-wifi/issues/new?template=hardware_issue.md) to report PCB problems, component issues, or design flaws
2. **Documentation Issues**: Use the [Documentation Issue template](https://github.com/the78mole/km271-wifi/issues/new?template=documentation_issue.md) to report unclear instructions, missing information, or errors
3. **Compatibility Issues**: Use the [Compatibility Report template](https://github.com/the78mole/km271-wifi/issues/new?template=compatibility_report.md) to report compatibility with specific Buderus controllers
4. **Bug Reports**: Use the [Bug Report template](https://github.com/the78mole/km271-wifi/issues/new?template=bug_report.md) for software bugs or unexpected behavior
5. **Feature Requests**: Use the [Feature Request template](https://github.com/the78mole/km271-wifi/issues/new?template=feature_request.md) to suggest new features or improvements

### Submitting Changes
1. **Fork the Repository**: Create your own fork of the project
2. **Create a Feature Branch**: Use descriptive branch names (e.g., `fix/i2c-pullup-issue`)
3. **Make Your Changes**: Follow the project structure and conventions
4. **Test Your Changes**: Validate hardware changes thoroughly
5. **Submit a Pull Request**: Provide clear description of changes and rationale

### Hardware Contributions
When contributing hardware changes:
- Include both original and modified files
- Provide Gerber files and manufacturing data
- Update documentation accordingly
- Test the design if possible
- Include 3D renders/photos of prototypes

## 📁 Project Structure

```
km271-wifi/
├── KM217-WiFi/          # Main PCB design files (KiCad)
├── EXTENSIONS/          # Extension board designs
├── DOC/                 # Documentation and guides  
├── IMG/                 # Images and photos
├── MECH/                # Mechanical designs (FreeCAD)
├── YAML/                # ESPHome configuration files
└── scripts/             # Automation and analysis scripts
```

## 🔧 Development Environment

### Hardware Design
- **KiCad**: Primary tool for PCB design
- **FreeCAD**: For mechanical components and enclosures
- **3D Modeling**: For visualizations and mechanical parts

### Documentation
- **Markdown**: For most documentation
- **LaTeX**: For PDF generation (Getting Started guides)
- **AsciiDoc**: Alternative documentation format

## 📄 License Requirements

This project is licensed under the **TAPR Open Hardware License** v1.0. When contributing:

### For Hardware Contributions:
- Your contributions will be licensed under the same TAPR OHL
- Include copyright notices on PCB artwork
- Maintain license compatibility with existing components

### For Documentation:
- Documentation contributions are subject to the same license terms
- Include appropriate copyright notices
- Maintain consistency with existing documentation format

### Patent Considerations:
- By contributing, you grant patent immunity as required by the TAPR OHL
- Do not contribute designs that infringe on third-party patents

## 🎨 Style Guidelines

### Hardware Design
- Follow existing KiCad design rules and layer stackup
- Use consistent component naming and values
- Include proper silkscreen labeling
- Maintain design for manufacturability principles

### Documentation
- Use clear, concise language
- Include diagrams and images where helpful
- Follow existing Markdown formatting conventions
- Provide both English and German versions where applicable

### Code & Scripts
- Follow existing code style and structure
- Include comments for complex logic
- Test scripts thoroughly before submission
- Update documentation for script changes

## 🏆 Recognition

Contributors are recognized in several ways:
- **Commit History**: All contributions are tracked in Git history
- **Documentation**: Significant contributors may be mentioned in project documentation
- **Hardware**: Contributors' names may be included on PCB silkscreen (space permitting)

## 📞 Getting Help

- **GitHub Discussions**: For general questions and community discussion
  - [💬 General Discussion](https://github.com/the78mole/km271-wifi/discussions) - General questions and ideas
  - [🆘 Help & Support](https://github.com/the78mole/km271-wifi/discussions/categories/q-a) - Get help with setup and troubleshooting
  - [🏭 Show & Tell](https://github.com/the78mole/km271-wifi/discussions/categories/show-and-tell) - Share your successful productions
- **GitHub Issues**: For specific bugs, feature requests, or hardware problems (use the appropriate templates)
- **Email**: Contact the maintainer at the78mole for direct hardware production questions

## 🚀 Hardware Production Notice

**Important**: If you successfully produce hardware based on this design, please notify the project maintainer. This helps:
- Track successful implementations
- Identify potential issues across different production runs
- Build a community of users and manufacturers
- Improve future hardware revisions

Include information about:
- Quantity produced
- Manufacturing location/service used
- Any assembly issues encountered
- Successful deployment details
- Photos of completed hardware (optional)

## 📈 Derivative Works

The TAPR Open Hardware License encourages derivative works. If you create modified versions:
- Maintain license compatibility
- Clearly identify your modifications
- Share your improvements with the community
- Consider contributing improvements back to the main project

## ⚡ Quick Start for Contributors

1. **Read the Documentation**: Start with the [Getting Started Guide](DOC/Getting_Started.md) and [Hardware Description](DOC/Hardware%20Description.md)
2. **Join the Community**: Participate in GitHub Discussions
3. **Identify Areas**: Look for open issues or areas needing improvement
4. **Start Small**: Begin with documentation improvements or small fixes
5. **Share Early**: Don't hesitate to share work-in-progress for feedback

Thank you for contributing to the KM271-WiFi project! Your contributions help make this open hardware design better for everyone.
