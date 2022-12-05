# A full git+maven+docker example

> **WARNING**: STILL WORK IN PROGESS 

This project generates a complete Java+Maven project ready for Continuous Integration (CI).
It is ready for GitFlow, SonarQube (tests, code coverage, ...). 
It can produce signed artifacts, fat jars, slim runtime with jLink, native executables with GraalVM 
and container images. The build itself can also be done in a container.

## Configuration (Once)
The configuration is done with environment variables.
For GitHub : GITHUB_ORG (GitHub account or organisation), GITHUB_LOGIN, GITHUB_TOKEN 
and optionally for SonarQube SONAR_URL and SONAR_TOKEN (To install SonarQube see https://github.com/ebpro/sonarqube)

Those variables have to be stored on the CI server (see [GitHub Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)).
The script below transforms the local variables in GitHub secrets.

```bash
bash -c 'for secret in GITHUB_LOGIN GITHUB_TOKEN SONAR_URL SONAR_TOKEN; do \
eval gh secret set $secret --app actions  \
                           --body ${!secret} \
                           --org ${GITHUB_ORG} \
                           --visibility all; \
done'
```

## Each new project

### Creation 

Generate each new project with this maven archetype (adapt the four last parameters).

<pre>
mvn --batch-mode archetype:generate \
    -DarchetypeGroupId=fr.univtln.bruno.demos.archetypes \
    -DarchetypeArtifactId=demomavenarchetype \
    -DarchetypeVersion=1.1-SNAPSHOT \
    -DgithubAccount=<b>ebpro</b> \
    -DgroupId=<b>fr.univtln.bruno.demos</b> \
    -DartifactId=<b>testci</b> \
    -Dversion=<b>1.0-SNAPSHOT</b>
</pre>

### GitFlow

1. Initialize git environment for GitFlow (develop and master branches).
2. Make a first commit.
3. Create the GitHub repository with the (gh CLI)[https://cli.github.com/].
3. Create an orphan gh-pages branch for the website.
4. Open the repository in a web browser.

```bash
git flow init -d && touch README.md && git add . && git commit -m "sets initial release." &&\
  gh repo create ${GITHUB_ORG}/${PWD##*/} --disable-wiki --public  --source=. --push &&\
    git checkout --orphan gh-pages && \
      git rm -rf . && touch index.html &&  \
      git add . && \
      git commit -m "sets initial empty site." && \
      git push --all \
    && git checkout develop &&\
  gh repo view --web
```

The project uses the [gitflow-maven-plugin](https://aleksandr-m.github.io/gitflow-maven-plugin) to manage 
GitFlow for java+Maven projet (branches and artifact version).

It is possible to easily start and finish a feature (see version in pom.xml).

```bash
mvn -B gitflow:feature-start  -DpushRemote=true -DfeatureName=UI
mvn -B gitflow:feature-start  -DpushRemote=true -DfeatureName=DB

mvn -B gitflow:feature-finish  -DpushRemote=true -DfeatureName=DB
mvn -B gitflow:feature-finish  -DpushRemote=true -DfeatureName=UI 
```

```bash
mvn -B gitflow:release-start -DpushRemote=true -DallowSnapshots=true -DuseSnapshotInRelease=true
mvn -B gitflow:release-finish -DpushRemote=true -DallowSnapshots=true
```

## Artefact packaging

### Compilation and execution

You can compile and package with unit tests.

```bash
mvn package
```

You can compile and package with unit tests and integration tests.

```bash
mvn verify
```

You can execute with maven (see app.mainClass property in pom.xml).

```bash
mvn exec:java
```

### Shaded Jar (close to FatJar or UberJar)

The profile `shadedjar` generates a fat jar with all the classes from the transitive dependencies.

```bash
mvn -Pshadedjar clean verify
ls -lh target/*.jar
```

-rw-r--r-- 1 bruno users 4,8K  7 nov.  20:05 target/fullgit-1.0-SNAPSHOT.jar<br/>
-rw-r--r-- 1 bruno users 635K  7 nov.  20:05 target/fullgit-1.0-SNAPSHOT-withdependencies.jar

The application can then be executed without maven : 

```bash
java -jar target/*-withdependencies.jar
```

### Jlink

Thanks to Jlink and a modular java project (jigsaw), it is possible to generate a minimal JRE 
with needed modules and dependencies. 

```bash
mvn -Pjlink clean verify
du -hs target/image
...
51M	target/image
```

The application can then be launched without a JRE installed.

```bash
❯ ./target/image/bin/myapp
Dec 02, 2022 11:18:56 PM fr.univtln.bruno.demos.App main
INFOS: Hello World! []
```

### GraalVM

It is also possible to generate a native binary with [GraalVM](https://www.graalvm.org/).
An installation of GraalVM is needed and the package build-essential libz-dev and zlib1g-dev 
(zlib-devel, zlib-static et glibc-static for fedora).

```bash
sdk install java 22.3.r19-grl
sdk use java 22.3.r19-grl
```

```bash
❯ mvn -Pnative clean verify
❯ ls -lh target/testci
-rwxr-xr-x 1 bruno users 13M  3 déc.  00:12 target/testci
❯ ./target/testci
déc. 03, 2022 12:15:25 AM fr.univtln.bruno.demos.App main
INFO: Hello World! []
```

### Building with Maven in docker
It is possible to build and run the project with just docker installed. 
A wrapper to run maven and java
in a container but to work with the current directory is proposed.
~/.m2, ~/.ssh, ~/.gitconfig and the src directories are mounted. 
The environment variables needed for the project are also transmitted. 
The UID and GID are the one of the current user.    

```bash
. ./wrappers.sh
docker-mvn clean -P shadedjar package
docker run --rm \
  --mount type=bind,source="$(PWD)"/target/,target=/app,readonly \
  eclipse-temurin:17-jre-alpine \
    sh -c "java -jar /app/*-withdependencies.jar"
```

### Docker Multistage build

The file `docker\Dockerfile` is a multistage Dockerfile to build and deliver 
the application with several strategies (shaded jar, jlink, GraalVM) 
on several distributions (debian and alpine). 
To ease the use a wrapper for docker commands is provided in dockerw.sh

```bash
. ./wrappers.sh
docker-wrapper-build
docker-wrapper-run
```

It is also possible to build all final target (Warning graalvm takes a long time to 
compile).

```bash
docker-wrapper-build-all
```

the result show the images and their size.

```
ebpro/testci   develop-finalShadedjarDebian   af3e072b35f7   2 hours ago   266MB
ebpro/testci   develop-finalShadedjarAlpine   38973a2aa588   2 hours ago   170MB
ebpro/testci   develop-finaljLinkDebian       db847ca5b281   2 hours ago   133MB
ebpro/testci   develop-finalJLinkAlpine       0cba42a81a33   2 hours ago   58.2MB
ebpro/testci   develop-finalGraalvmDebian     f5607a1e055f   2 hours ago   93.7MB
ebpro/testci   develop-finalGraalvmAlpine     d9c0573e4750   2 hours ago   18.8MB
```

It is also possible to run all the images :

```bash
docker-wrapper-run-all
```

```log
INFO: Hello World! []
  0,06s user 0,04s system 6% cpu 1,529 total
Running ebpro/testci:develop-finalShadedjarAlpine
Dec 05, 2022 4:37:06 PM fr.univtln.bruno.demos.App main
INFO: Hello World! []
  0,05s user 0,05s system 5% cpu 1,724 total
Running ebpro/testci:develop-finaljLinkDebian
Dec 05, 2022 4:37:07 PM fr.univtln.bruno.demos.App main
INFO: Hello World! []
  0,05s user 0,05s system 5% cpu 1,690 total
Running ebpro/testci:develop-finalJLinkAlpine
Dec 05, 2022 4:37:09 PM fr.univtln.bruno.demos.App main
INFO: Hello World! []
  0,04s user 0,05s system 5% cpu 1,723 total
Running ebpro/testci:develop-finalGraalvmDebian
Dec 05, 2022 4:37:10 PM fr.univtln.bruno.demos.App main
INFO: Hello World! []
  0,05s user 0,03s system 7% cpu 1,161 total
Running ebpro/testci:develop-finalGraalvmAlpine
Dec 05, 2022 4:37:12 PM fr.univtln.bruno.demos.App main
INFO: Hello World! []
```



### Quality

If a sonarqube server is available (i.e with https://github.com/ebpro/sonarqube).
Set the variable SONAR_URL and SONAR_TOKEN

```bash
mvn -P jacoco,sonar \
  -Dsonar.branch.name=$(git rev-parse --abbrev-ref HEAD | tr / _) \
  verify sonar:sonar 
```

#TODO: FIX LOST CODE COVERAGE 
```bash
mvn clean verify
mvn -DskipTests=true \
    -Dsonar.branch.name=$(git rev-parse --abbrev-ref HEAD | tr / _) \
    -P jacoco,sonar \
    sonar:sonar
```

### Web site

```bash
mvn site:site
```