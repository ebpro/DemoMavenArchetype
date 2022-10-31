# syntax=docker/dockerfile:1
FROM brunoe/maven:3.8.6-eclipse-temurin-17 AS build

WORKDIR /myproject

# We git important parameteres as build-arg
ARG GITHUBLOGIN
ARG GITHUBPASSWORD
# and we transfer them as env variable (for maven settings substitution).
ENV GITHUBLOGIN=$GITHUBLOGIN
ENV GITHUBPASSWORD=$GITHUBPASSWORD

COPY pom.xml .
COPY src src
COPY docker-image/ci-settings.xml .
RUN --mount=type=cache,id=mvncache,target=/root/.m2/repository,rw \
	mvn -s ci-settings.xml -B package

# Create a custom Java runtime from the dev env.
RUN MODULES=`jdeps  --ignore-missing-deps --list-deps target/*-withdependencies.jar| grep -v -e jdk.compiler -e sun.security.krb5 | tr '\n' ','| tr -d "[:space:]"|head -c -1`  \
    && $JAVA_HOME/bin/jlink \
         --add-modules  $MODULES\
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

FROM debian:bullseye-slim
# Copy the JRE from the dev build env
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=build /javaruntime $JAVA_HOME

# Copy the uber Jar from the dev build env
COPY --from=build /myproject/target/*-withdependencies.jar \
		  /myapp.jar

# Adds the wait script (see variable in docker-compose.yml)
ENV WAIT_VERSION 2.9.0
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait

ENTRYPOINT ["/bin/sh", "-c", "/wait && java -jar /myapp.jar"]
