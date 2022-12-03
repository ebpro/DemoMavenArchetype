docker-mvn() (docker run \
  --env GITHUB_LOGIN=$GITHUB_LOGIN \
  --env GITHUB_PASSWORD=$GITHUB_PASSWORD \
  --env SONAR_URL=$SONAR_URL \
  --env SONAR_TOKEN=$SONAR_TOKEN \
  --volume ~/.m2:/var/maven/.m2 \
  --volume ~/.ssh:/home/user/.ssh \
  --volume ~/.gitconfig:/home/user/.gitconfig \
  --volume "$(pwd)":/usr/src/mymaven \
  --workdir /usr/src/mymaven \
  --rm \
  --env PUID=`id -u` -e PGID=`id -g` \
  --env MAVEN_CONFIG=/var/maven/.m2 \
  ${MAVEN_IMAGE:-brunoe/maven:3.8.6-eclipse-temurin-17} \
  runuser --user user \
          --group user \
          -- mvn -B -e -T 1C \
              -Duser.home=/var/maven \
              --settings /usr/src/mymaven/docker-files/ci-settings.xml "$@"
)
