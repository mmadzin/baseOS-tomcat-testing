#!/bin/bash 

BOUNCY_LIB_VERSION=1.83
DIR="~/tomcat-build-libs/bouncycastle-${BOUNCY_LIB_VERSION}"

mkdir -p ${DIR}
wget https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-jdk18on/${BOUNCY_LIB_VERSION}/bcpkix-jdk18on-${BOUNCY_LIB_VERSION}.jar ${DIR}/bouncycastle-pkix-${BOUNCY_LIB_VERSION}.jar
wget https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BOUNCY_LIB_VERSION}/bcprov-jdk18on-${BOUNCY_LIB_VERSION}.jar ${DIR}/bouncycastle-provider-${BOUNCY_LIB_VERSION}.jar
