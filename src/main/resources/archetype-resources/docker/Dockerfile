# syntax=docker/dockerfile:1


########## BUILD IN UBUNTU ##########
FROM maven:3.8-eclipse-temurin-17-focal AS ubuntubuild
# We get important parameters as build-args
# and we transfer them as env variable (for maven settings substitution) with ENV.
# WARNING NEVER IN THE LAST STAGE
ARG GITHUB_LOGIN
ARG GITHUB_TOKEN
ARG SONAR_URL
ARG SONAR_TOKEN
ARG DOCKER_LOGIN
ARG DOCKER_TOKEN
ARG IMAGE_NAME
ENV GITHUB_LOGIN="$GITHUB_LOGIN"
ENV GITHUB_TOKEN="$GITHUB_TOKEN"
ENV SONAR_URL="$SONAR_URL"
ENV SONAR_TOKEN="$SONAR_TOKEN"
ENV DOCKER_LOGIN="$DOCKER_LOGIN"
ENV DOCKER_TOKEN="$DOCKER_TOKEN"
ENV IMAGE_NAME="$IMAGE_NAME"
# The will be build in /myproject directory in the container
WORKDIR /myproject
# We copy the sources
COPY pom.xml .
COPY src src
# and specific settings.xml for CI
COPY docker/ci-settings.xml .
# We build the project and produce the artefact
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
	mvn -s ci-settings.xml -B -Pshadedjar clean verify

########## SHADED JAR FROM UBUNTU TO UBUNTU JRE ##########
FROM eclipse-temurin:17-jre-jammy as finalShadedjarDebian
ENV IMAGE_NAME=${IMAGE_NAME}
COPY --from=ubuntubuild /myproject/target/*-withdependencies.jar /${IMAGE_NAME}.jar
ENTRYPOINT java -jar /${IMAGE_NAME}.jar
########## SHADED JAR FROM UBUNTU TO ALPINE ##########
FROM eclipse-temurin:17-jre-alpine as finalShadedjarAlpine
COPY --from=ubuntubuild /myproject/target/*-withdependencies.jar /${IMAGE_NAME}.jar
ENTRYPOINT java -jar /${IMAGE_NAME}.jar

########## JLINK FROM UBUNTU to DEBIAN ##########
FROM ubuntubuild AS jlinkUbuntuBuild
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
	mvn -s ci-settings.xml -B -Pjlink verify
FROM debian:bullseye-slim as finaljLinkDebian
# Copy the JRE and the modules
COPY --from=jlinkUbuntuBuild /myproject/target/image /${IMAGE_NAME}
ENTRYPOINT /${IMAGE_NAME}/bin/myapp

########## JLINK FROM ALPINE (needed for the right JRE binary) to ALPINE ##########
FROM maven:3.8.6-eclipse-temurin-17-alpine AS jlinkAlpineBuild
ARG GITHUB_LOGIN
ARG GITHUB_TOKEN
ARG SONAR_URL
ARG SONAR_TOKEN
ARG DOCKER_LOGIN
ARG DOCKER_TOKEN
ARG IMAGE_NAME
ENV GITHUB_LOGIN="$GITHUB_LOGIN"
ENV GITHUB_TOKEN="$GITHUB_TOKEN"
ENV SONAR_URL="$SONAR_URL"
ENV SONAR_TOKEN="$SONAR_TOKEN"
ENV DOCKER_LOGIN="$DOCKER_LOGIN"
ENV DOCKER_TOKEN="$DOCKER_TOKEN"
ENV IMAGE_NAME="$IMAGE_NAME"
WORKDIR /myproject
COPY pom.xml .
COPY src src
COPY docker/ci-settings.xml .
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
    mvn -s ci-settings.xml -B -Pjlink clean verify
FROM alpine as finalJLinkAlpine
ARG IMAGE_NAME
ENV IMAGE_NAME=${IMAGE_NAME}
COPY --from=jlinkAlpineBuild /myproject/target/image /${IMAGE_NAME}
ENTRYPOINT /${IMAGE_NAME}/bin/myapp

########## GRAALVM FROM DEBIAN to DEBIAN and ALPINE ##########
FROM debian:11-slim as graalvmBuild
ARG JAVA_VERSION="22.3.r17-grl"
ARG MAVEN_VERSION="3.8.6"
ENV SDKMAN_DIR=/root/.sdkman

ARG GITHUB_LOGIN
ARG GITHUB_TOKEN
ARG SONAR_URL
ARG SONAR_TOKEN
ARG DOCKER_LOGIN
ARG DOCKER_TOKEN
ARG IMAGE_NAME
ENV GITHUB_LOGIN="$GITHUB_LOGIN"
ENV GITHUB_TOKEN="$GITHUB_TOKEN"
ENV SONAR_URL="$SONAR_URL"
ENV SONAR_TOKEN="$SONAR_TOKEN"
ENV DOCKER_LOGIN="$DOCKER_LOGIN"
ENV DOCKER_TOKEN="$DOCKER_TOKEN"
ENV IMAGE_NAME="$IMAGE_NAME"
RUN apt-get update && apt-get install -y --no-install-recommends tzdata curl zip unzip build-essential libz-dev zlib1g-dev ca-certificates fontconfig locales \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && curl 'https://get.sdkman.io' | bash \
    && echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config \
    && echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config \
    && echo "sdkman_insecure_ssl=true" >> $SDKMAN_DIR/etc/config \
    && chmod +x $SDKMAN_DIR/bin/sdkman-init.sh
SHELL ["/bin/bash", "-c"]
RUN source $SDKMAN_DIR/bin/sdkman-init.sh \
        && sdk version \
        && sdk install java $JAVA_VERSION \
        && gu install native-image \
        && gu install js \
        && sdk install maven $MAVEN_VERSION \
        && rm -rf $SDKMAN_DIR/archives/* \
        && rm -rf $SDKMAN_DIR/tmp/*
WORKDIR /myproject
COPY pom.xml .
COPY src src
COPY docker/ci-settings.xml .
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
	source $SDKMAN_DIR/bin/sdkman-init.sh && \
	mvn -s ci-settings.xml -B -Pnative clean verify

FROM debian:11-slim as finalGraalvmDebian
ARG IMAGE_NAME
ENV IMAGE_NAME=${IMAGE_NAME}
COPY --from=graalvmBuild /myproject/target/${IMAGE_NAME} /
ENTRYPOINT /${IMAGE_NAME}

FROM alpine as finalGraalvmAlpine
ARG IMAGE_NAME
ENV IMAGE_NAME=${IMAGE_NAME}
COPY --from=graalvmBuild /myproject/target/${IMAGE_NAME} /
ENTRYPOINT /${IMAGE_NAME}
