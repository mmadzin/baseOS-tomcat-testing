#!/bin/bash 

BOUNCY_LIB_VERSION=1.83
PATH="tomcat-build-libs/bouncycastle-${BOUNCY_LIB_VERSION}"

mkdir -p ${PATH}
wget https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-jdk18on/${BOUNCY_LIB_VERSION}/bcpkix-jdk18on-${BOUNCY_LIB_VERSION}.jar ${PATH}/bouncycastle-pkix-${BOUNCY_LIB_VERSION}.jar
wget https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BOUNCY_LIB_VERSION}/bcprov-jdk18on-${BOUNCY_LIB_VERSION}.jar ${PATH}/bouncycastle-provider-${BOUNCY_LIB_VERSION}.jar
