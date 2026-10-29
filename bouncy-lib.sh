#!/bin/bash
set -e

BOUNCY_LIB_VERSION=1.83
TARGET_DIR="${HOME}/tomcat-build-libs/bouncycastle-${BOUNCY_LIB_VERSION}"

mkdir -p "${TARGET_DIR}"

wget "https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-jdk18on/${BOUNCY_LIB_VERSION}/bcpkix-jdk18on-${BOUNCY_LIB_VERSION}.jar" \
     -O "${TARGET_DIR}/bouncycastle-pkix-${BOUNCY_LIB_VERSION}.jar"

wget "https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BOUNCY_LIB_VERSION}/bcprov-jdk18on-${BOUNCY_LIB_VERSION}.jar" \
     -O "${TARGET_DIR}/bouncycastle-provider-${BOUNCY_LIB_VERSION}.jar"
