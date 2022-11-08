# A full git+maven+docker example

!!!! WORK IN PROGESS !!!! 

AJOUTER UNE EXCLUSION GLOBALE A SONAR **/module-info.java

## Pre configuration 
Sets environment variables for logins and tokens to access GitHub and sonar.    
The next script transforms them in GitHub secrets.
```bash
bash -c 'for secret in GITHUBLOGIN GITHUBPASSWORD SONAR_URL SONAR_TOKEN; do \                                                              
eval gh secret set $secret --app actions  --body ${!secret} --org $GITHUB_ORG --visibility all; \
done'
```

and install SonarQube : https://github.com/ebpro/sonarqube

## Creation
```bash
mvn --batch-mode archetype:generate \
-DarchetypeGroupId=fr.univtln.bruno.demos.archetypes \
-DarchetypeArtifactId=demomavenarchetype \
-DarchetypeVersion=1.1-SNAPSHOT \
-DgithubAccount=ebpro \
-DgroupId=fr.univtln.bruno.demos \
-DartifactId=testci \
-Dversion=1.0-SNAPSHOT
```
```bash
git flow init -d
touch README.md && git add . && git commit -m "sets initial release."
gh repo create ebpro/${PWD##*/} --disable-wiki --public  --source=. --push
git checkout --orphan gh-pages && \
    git rm -rf . && touch index.html &&  \
    git add . && \
    git commit -m "sets initial empty site." && \
    git push --all \
    && git checkout develop
gh repo view --web
```
## Gitflow

https://aleksandr-m.github.io/gitflow-maven-plugin

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
### Compilation
```bash
mvn clean verify
```
### Exécution
```bash
mvn exec:java
```

## Shaded Jar (close to FatJar or UberJar)
```bash
mvn -Pshadedjar clean verify
ls -lh target/*.jar
```
-rw-r--r-- 1 bruno users 4,8K  7 nov.  20:05 target/fullgit-1.0-SNAPSHOT.jar
-rw-r--r-- 1 bruno users 635K  7 nov.  20:05 target/fullgit-1.0-SNAPSHOT-withdependencies.jar

### Exécution
```bash
java -jar target/*-withdependencies.jar
```
### Docker Multistage build
With a JRE full image and the shaded Jar.
```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build shaded
docker run --rm brunoe/fullgit:master
```
###  Docker Multistage build
## Jlink
```bash
mvn -Pjlink clean verify
du -hs target/maven-jlink/classifiers/jlink
```
### Exécution
```bash
target/maven-jlink/classifiers/jlink/bin/default
```
### Docker image Multistage build
```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build jlink
```

## GraalVM
Install GraalVM
```bash
sdk install java 22.3.r19-grl
sdk use java 22.3.r19-grl
```

```bash
mvn -Pnative clean verify
ls -lh target/fullgit
```
### Exécution
```bash
target/maven-jlink/classifiers/jlink/bin/default
```
### Docker image Multistage build
```bash
./docker-utils/docker_compose.sh -f docker-files/docker-compose.yml build graalvm
```