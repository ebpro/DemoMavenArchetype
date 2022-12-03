# A full git+maven+docker example

> **WARNING**: STILL WORK IN PROGESS 

This project generates a complete Java+Maven project ready for Continuous Integration (CI).
It is ready for GitFlow, SonarQube (tests, code coverage, ...). 
It can produce signed artifacts, fat jars, slim runtime with jLink, native executables with GraalVM 
and container images. The build can alse be done in a container.

## Configuration (Once)
The configuration is done with environment variables.
For GitHub : GITHUB_ORG (GitHub account or organisation), GITHUB_LOGIN, GITHUB_TOKEN

And optionally for SonarQube set SONAR_URL and SONAR_TOKEN 
and install SonarQube : https://github.com/ebpro/sonarqube

Those variables have to be stored on the CI server (see [GitHub Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)).
The next script transforms the local variables in GitHub secrets.

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

## A simple jar artefact

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

Thanks to Jlink and a modular (jigsaw) java project, it is possible to generation a minimal JRE, modules 
and dependencies. 

```bash
mvn -Pjlink clean verify
du -hs target/image
```

The application can then be launch without a JRE installed.

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

### Docker Multistage build

With a JRE full image and the shaded Jar.

```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build shaded
docker run --rm brunoe/fullgit:master
```

```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build jlink
```

```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build graalvm
```

### Quality

Java code coverage

SonarQube