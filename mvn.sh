#!/bin/bash
export MAVEN_IMAGE=brunoe/maven:3.8.2-adoptopenjdk-16
docker run \
          --env GITHUBLOGIN=$GITHUBLOGIN \
          --env GITHUBPASSWORD=$GITHUBPASSWORD \
          --volume ~/.m2:/var/maven/.m2 \
          --volume ~/.ssh:/home/user/.ssh \
          --volume ~/.gitconfig:/home/user/.gitconfig \
          --volume "$(pwd)":/usr/src/mymaven \
          --workdir /usr/src/mymaven \
          --rm \
          --env PUID=`id -u` -e PGID=`id -g` \
          --env MAVEN_CONFIG=/var/maven/.m2 \
          $MAVEN_IMAGE \
          runuser --user user --group user -- mvn -B -e -T 1C -Duser.home=/var/maven --settings /usr/src/mymaven/.github/ci-settings.xml "$@"