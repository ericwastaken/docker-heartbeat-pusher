#!/bin/bash
#===============================================================================
# SCRIPT:       x_deploy.sh
# DESCRIPTION:  Tags and pushes Docker images for the current project
#               Supports both multi-platform and single platform deployments
#
# USAGE:        ./x_deploy.sh
#
# DEPENDENCIES: 
#   - docker
#   - docker buildx (for multi-platform deployments)
#   - docker-build-manifest.env file with required variables
#   - User must be logged into Docker registry
#
# ENVIRONMENT VARIABLES (from docker-build-manifest.env):
#   - NAME: Name of the Docker image
#   - CURR_TAG: Current tag for the Docker image
#
# NOTES:
#   - For multi-platform deployments, Docker buildx with QEMU support is required
#   - Multi-platform deployments support linux/amd64 and linux/arm64
#   - The script will tag the image with both the current tag and 'latest'
#===============================================================================

# Load environment variables from build-manifest.env
source docker-build-manifest.env

# Check that the user is logged into docker
if ! docker info > /dev/null 2>&1; then
  echo "You need to be logged into Docker to run this script!"
  exit 1
fi

# Confirm that we want to tag and push current
echo "Tagging and pushing current image to $NAME:$CURR_TAG"
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# ask if we want to push multi-platform or current platform only
echo "Do you want to push the image for multi platform or current platform only?"
echo "1. Multi platform (Requires docker buildx support qith qemu - built into macOS Docker Desktop)"
echo "2. Current platform only"
read -p "Enter your choice: " choice
case $choice in
  1)
    echo "Tagging & Pushing the image for multi platform"
    docker buildx build --platform linux/amd64,linux/arm64 -t $NAME:$CURR_TAG -t $NAME:latest --push .
    ;;
  2)
    echo "Tagging & Pushing the image for current platform only"
    docker build -t $NAME:$CURR_TAG .
    docker tag $NAME:$CURR_TAG $NAME:latest
    docker push $NAME:$CURR_TAG
    docker push $NAME:latest
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac
