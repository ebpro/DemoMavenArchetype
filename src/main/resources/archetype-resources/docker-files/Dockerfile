# syntax=docker/dockerfile:1
#FROM brunoe/maven:3.8.6-eclipse-temurin-17 AS build
FROM maven:3.8-eclipse-temurin-17-focal AS build

WORKDIR /myproject

# We git important parameteres as build-arg
ARG GITHUB_LOGIN
ARG GITHUB_TOKEN
# and we transfer them as env variable (for maven settings substitution).
ENV GITHUB_LOGIN=$GITHUB_LOGIN
ENV GITHUB_TOKEN=$GITHUB_TOKEN

COPY pom.xml .
COPY src src
COPY docker-files/ci-settings.xml .
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
	mvn -s ci-settings.xml -B -Pshadedjar clean verify

FROM eclipse-temurin:17-jre
COPY --from=build /myproject/target/*-withdependencies.jar /myapp.jar

ENTRYPOINT java -jar /myapp.jar
