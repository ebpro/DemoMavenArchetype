#!/bin/bash

###
# #%L
# Demo Maven Archetype
# %%
# Copyright (C) 2020 - 2022 Université de Toulon
# %%
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# #L%
###

# This utility function computes the image name and tag from the project directory and the git branch.
_docker_env() {
  DOCKER_REPO_NAME=${GITHUB_ORG}
  IMAGE_NAME=$(echo ${PWD##*/} | tr '[:upper:]' '[:lower:]')
  IMAGE_TAG=$(git rev-parse --abbrev-ref HEAD)
  DOCKER_TARGET=${DOCKER_TARGET:-finalJLinkAlpine}
  DOCKER_FULL_IMAGE_NAME="$DOCKER_REPO_NAME/$IMAGE_NAME:$IMAGE_TAG-$DOCKER_TARGET"
}

# This utility function look for final target in the docker file and compute docker image name and tag (oen by line).
_docker-wrapper-all-images() (
  for finalTarget in $(grep -E 'FROM.*final.*' docker/Dockerfile | tr -s ' ' | cut -f 4 -d ' '); do
    DOCKER_TARGET="$finalTarget" _docker_env
    echo "$finalTarget#${DOCKER_FULL_IMAGE_NAME}"
  done
)

# This function is a wrapper around the docker command to passes the env (credentials, image names, ...)
docker-wrapper() (
  _docker_env
  DOCKER_BUILDKIT=1 \
    docker "$1" \
    --file docker/Dockerfile \
    --build-arg IMAGE_NAME="$IMAGE_NAME" \
    --build-arg DOCKER_USERNAME="$DOCKER_USERNAME" \
    --build-arg DOCKER_PASSWORD="$DOCKER_PASSWORD" \
    --build-arg SONAR_TOKEN="$SONAR_TOKEN" \
    --build-arg SONAR_URL="$SONAR_URL" \
    --build-arg GITHUB_LOGIN="$GITHUB_LOGIN" \
    --build-arg GITHUB_TOKEN="$GITHUB_TOKEN" \
    --target "${DOCKER_TARGET}" \
    -t "${DOCKER_FULL_IMAGE_NAME}" \
    "${@: -1}"
)

# Build a target image ($DOCKER_TARGET)
docker-wrapper-build() (
  docker-wrapper build "$@" .
)

# Builds images for final targets of the Dockerfile
docker-wrapper-build-all() (
  for image in $(_docker-wrapper-all-images); do
    finalTarget=$(echo "$image" | cut -f1 -d '#' -)
    DOCKER_TARGET="$finalTarget" docker-wrapper-build "$@"
  done
  for image in $(_docker-wrapper-all-images); do
    imageName=$(echo "$image" | cut -f2 -d '#' -)
    docker image ls "$imageName" | tail -n+2
  done
)

# Runs a target image ($DOCKER_TARGET)
docker-wrapper-run() (
  _docker_env
  echo "Running ${DOCKER_FULL_IMAGE_NAME}"
  docker run --rm -it "${DOCKER_FULL_IMAGE_NAME}"
)

#Runs all the final targets
docker-wrapper-run-all() (
  for image in $(_docker-wrapper-all-images); do
    finalTarget=$(echo "$image" | cut -f1 -d '#' -)
    time (DOCKER_TARGET="$finalTarget" docker-wrapper-run "$@")
  done
)

# Runs maven in a container as the user
# see https://github.com/ebpro/docker-maven
docker-mvn() (
  _docker_env
  docker run \
    --env IMAGE_NAME="$IMAGE_NAME" \
    --env GITHUB_LOGIN="$GITHUB_LOGIN" \
    --env GITHUB_TOKEN="$GITHUB_TOKEN" \
    --env SONAR_URL="$SONAR_URL" \
    --env SONAR_TOKEN="$SONAR_TOKEN" \
    --env SONAR_URL="$SONAR_URL" \
    --env SONAR_TOKEN="$SONAR_TOKEN" \
    --env S6_LOGGING=1 \
    --env S6_BEHAVIOUR_IF_STAGE2_FAILS \
    --volume ~/.m2:/home/user/.m2 \
    --volume ~/.ssh:/home/user/.ssh \
    --volume ~/.gitconfig:/home/user/.gitconfig \
    --volume "$(pwd)":/usr/src/mymaven \
    --workdir /usr/src/mymaven \
    --rm \
    --env PUID=$(id -u) -e PGID=$(id -g) \
    --env MAVEN_CONFIG=/home/user/.m2 \
    "${MAVEN_IMAGE:-brunoe/maven:3.8.6-eclipse-temurin-17}" \
    runuser --user user \
            --group user \
            -- mvn --errors --threads 1C --color always --strict-checksums \
                   -Duser.home=/home/user \
                   --settings /usr/src/mymaven/docker/ci-settings.xml "$@"
)

docker-sonar-analysis() (
  mvn -P jacoco,sonar \
    -Dsonar.branch.name=$(git rev-parse --abbrev-ref HEAD | tr / _) \
    verify sonar:sonar
)

new-java-project() (
 mvn --quiet --color=always --batch-mode archetype:generate \
    -DarchetypeGroupId=fr.univtln.bruno.demos.archetypes \
    -DarchetypeArtifactId=demomavenarchetype \
    -DarchetypeVersion=1.1-SNAPSHOT \
    -DgithubAccount=ebpro \
    -DgroupId=${2:-fr.univtln.bruno.demos} \
    -DartifactId=${1:-testci} \
    -Dversion=1.0-SNAPSHOT &&\
 cd ${1:-testci} &&\
 git flow init -d && touch README.md && git add . && git commit -m "sets initial release." &&\
  gh repo create ${GITHUB_ORG}/${PWD##*/} --disable-wiki --public  --source=. --push &&\
    git checkout --orphan gh-pages && \
      git rm -rf . && touch index.html &&  \
      git add . && \
      git commit -m "sets initial empty site." && \
      git push --all \
    && git checkout develop &&\
  gh repo view --web &&\
  cd ${1:-testci}
)
