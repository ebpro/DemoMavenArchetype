#!/bin/bash
docker run \
          -e GITHUBLOGIN=$GITHUBLOGIN \
          -e GITHUBPASSWORD=$GITHUBPASSWORD \
          -v ~/.m2:/var/maven/.m2 \
          -v "$(pwd)":/usr/src/mymaven \
          -w /usr/src/mymaven \
          --rm \
          -u `id -u` \
          -e MAVEN_CONFIG=/var/maven/.m2 \
          maven:3.6.3-jdk-11-openj9 \
          mvn -B -e -T 1C -Duser.home=/var/maven --settings /usr/src/mymaven/.github/ci-settings.xml "$@"