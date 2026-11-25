"""StrictDoc project configuration for the KM271-WiFi requirements.

Local preview:  pip install strictdoc==0.32.1 && strictdoc server .
Static export:  strictdoc export . --formats html,html2pdf,reqif-sdoc,json,excel
The release workflow publishes the HTML export to GitHub Pages.
"""

from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="KM271-WiFi Requirements",
        include_doc_paths=[
            "KM217-WiFi/req/**",
            "EXTENSIONS/ETH_W5500/req/**",
        ],
        exclude_doc_paths=[
            "**/README.md",
        ],
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "TRACEABILITY_MATRIX_SCREEN",
            "PROJECT_STATISTICS_SCREEN",
            "TREE_MAP_SCREEN",
            "SEARCH",
            "HTML2PDF",
            "REQIF",
            "MERMAID",
        ],
    )
