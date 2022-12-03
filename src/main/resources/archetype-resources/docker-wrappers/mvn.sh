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

export MAVEN_IMAGE=brunoe/maven:3.8.6-eclipse-temurin-17
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
