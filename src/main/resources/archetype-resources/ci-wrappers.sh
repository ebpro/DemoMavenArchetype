#!/bin/bash

_B_TITLE='\033[0;33m'
_E_TITLE='\033[0;0m'

ci-wrappers-usage() {
  echo "install-dockerclient-vagrant\n\t installs a docker client and vagant in ~/bin"
  echo "new-java-project [projectname]\n\t create a new java+maven project ready for CI"
  echo "docker-wrapper"
  echo "docker-wrapper-build"
  echo "docker-wrapper-build-all"
  echo "docker-wrapper-run-all"
  echo "docker-mvn"
  echo "docker-sonar-analysis"
}

install-dockerclient-vagrant() {
  mkdir -p ~/bin &&
    if [ -f ~/bin/vagrant ]; then
      export PATH=~/bin:$PATH &&
        wget -qO- https://releases.hashicorp.com/vagrant/2.3.3/vagrant_2.3.3_linux_amd64.zip | gunzip - \
          >~/bin/vagrant &&
        chmod +x ~/bin/vagrant
    else
      echo "vagrant already installed"
    fi
}

provision-docker-engine() {
  _check_variables VAGRANT_HTTP_PROXY VAGRANT_HTTPS_PROXY VAGRANT_NO_PROXY
}

_moveVBoxDefaultFolder() {
  targetdirectory=${1:-/scratch/${USER}}
  VBoxManage list systemproperties | grep "Current default machine folder:" &&
    mkdir -p ${targetirectory} &&
    vboxmanage setproperty machinefolder ${targetirectory}/VirtualBox\ VMs &&
    echo -n "New " && VBoxManage list systemproperties | grep "Default machine folder:"
}

_check_needed_software() {
  for c in docker vagrant; do
    if [ -x "$(command -v ${c})" ]; then
      echo $c not found
    else
      echo $c found
    fi
  done
}

_check_needed_variables() {
  _check_variables GITHUBLOGIN GITHUBTOKEN GITHUB_ORG SONAR_URL SONAR_TOKEN
}

_check_variables() {
  if [ -n "$ZSH_VERSION" ]; then emulate -L bash; fi
  for varname in "$@"; do
    v="${!varname}"
    if [ ! -n "${v-unset}" ]; then
      echo "$varname is not set: exiting"
      exit 1
    fi
  done
}

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
    --volume "$
    }(pwd)":/usr/src/mymaven \
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
  docker-mvn -P jacoco,sonar \
    -Dsonar.branch.name=$(git rev-parse --abbrev-ref HEAD | tr / _) \
    verify sonar:sonar
)

new-java-project() (
  printf "${_B_TITLE}Creating Java project ${_E_TITLE}"
  if [[ ! $# -eq 2 ]]; then
    echo "Usage: $0 <projectname> <groupid>"
    exit 1
  fi
  _check_variables GITHUBLOGIN GITHUBORG GITHUBTOKEN
  printf "${_B_TITLE}$1 with groupId $2${_E_TITLE}\n"
  printf "${_B_TITLE}  calling maven archetype${_E_TITLE}\n"
  mvn --quiet --color=always --batch-mode archetype:generate \
    -DarchetypeGroupId=fr.univtln.bruno.demos.archetypes \
    -DarchetypeArtifactId=demomavenarchetype \
    -DarchetypeVersion=1.1-SNAPSHOT \
    -DgithubAccount=${GITHUBORG} \
    -DgroupId=${2} \
    -DartifactId=${1} \
    -Dversion=1.0-SNAPSHOT &&
    cd ${1} &&
    printf "${_B_TITLE}  Gitflow init${_E_TITLE}\n" &&
  git flow init -d && touch README.md && git add . && git commit -m "sets initial release." &&
    printf "${_B_TITLE}  GitHub reposirory creation${_E_TITLE}\n" &&
  gh repo create ${GITHUBORG}/${PWD##*/} --disable-wiki --public --source=. --push &&
    git checkout --orphan gh-pages &&
    git rm -rf . && touch index.html &&
    git add . &&
    git commit -m "sets initial empty site." &&
    git push --all &&
    git checkout develop &&
    gh repo view --web &&
    printf "${_B_TITLE}  Generate a default deploy key${_E_TITLE}\n" &&
    _generate_and_install_new_deploy_key
)

_generate_and_install_new_deploy_key() (
  tmpKeydir=$(mktemp --directory /tmp/ci-wrappers.XXXXXX)
  ssh-keygen -q -t ed25519 -C "An autogenerated deploy key" -N "" -f ${tmpKeydir}/key
  gh repo deploy-key add --allow-write "${tmpKeydir}/key.pub"
  gh secret set SECRET_DEPLOY_KEY < "${tmpKeydir}/key"
  rm -rf tmpKeydir
)