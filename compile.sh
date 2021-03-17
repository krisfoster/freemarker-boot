#!/usr/bin/env bash

ARTIFACT=demo-0.0.1-SNAPSHOT
MAINCLASS=com.example.demo.DemoApplication
#VERSION=0.0.1-SNAPSHOT

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

#rm -rf build

mkdir -p build/native-image

JAR="$ARTIFACT.jar"
#rm -f $ARTIFACT
echo "Unpacking $JAR"
cd build/native-image
jar -xvf ../../target/$JAR >/dev/null 2>&1
#cp -R META-INF BOOT-INF/classes

# To run tracing agent
# java -cp WEB-INF/classes:WEB-INF/lib/*:WEB-INF/lib-provided/* -agentlib:native-image-agent=config-output-dir=../graal-agent com.vue.labs.LocalAbeServiceApplication

LIBPATH=$(find BOOT-INF/lib | tr '\n' ':')
CP=BOOT-INF/classes:$LIBPATH:META-INF:.



GRAALVM_VERSION=$(native-image --version)
echo "Compiling $ARTIFACT with $GRAALVM_VERSION"
time native-image \
  --enable-all-security-services \
  --no-server \
  --no-fallback \
  --verbose \
  --trace-class-initialization=org.springframework.util.ClassUtils \
  --initialize-at-build-time=org.springframework.util.ClassUtils \
  --allow-incomplete-classpath \
  -H:Name=$ARTIFACT \
  -H:+ReportExceptionStackTraces \
  -Dspring.native.remove-yaml-support=true \
  -Dspring.xml.ignore=false \
  -Dspring.spel.ignore=true \
  --trace-object-instantiation=sun.security.provider.NativePRNG \
  --initialize-at-run-time=org.hibernate.validator.internal.engine.messageinterpolation.el.SimpleELContext \
  --initialize-at-build-time=org.apache.commons.logging.LogFactory,org.apache.commons.lang3.StringUtils,com.vue.io.VueConfigUtils \
  --rerun-class-initialization-at-runtime=org.bouncycastle.jcajce.provider.drbg.DRBG\$Default,org.bouncycastle.jcajce.provider.drbg.DRBG\$NonceAndIV,sun.security.provider.NativePRNG,sun.security.ssl.SSLContextImpl\$AbstractTLSContext \
  -cp $CP $MAINCLASS

# sun.security.ssl.SSLContextImpl$AbstractTLSContext
#   -H:Log=registerResource \

if [[ -f $ARTIFACT ]]; then
  printf "${GREEN}SUCCESS${NC}\n"
  mv ./$ARTIFACT ..
  exit 0
else
  printf "${RED}FAILURE${NC}: an error occurred when compiling the native-image.\n"
  exit 1
fi
