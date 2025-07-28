#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "🧹 Cleaning export directories for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Create/clean export directories
mkdir -p Export/Gerbers
mkdir -p Export/Drill
mkdir -p Export/PDF
mkdir -p Export/Images
mkdir -p Export/3D

# Clean old files
rm -f Export/Gerbers/*
rm -f Export/Drill/*
rm -f Export/PDF/*
rm -f Export/Images/*
rm -f Export/3D/*
