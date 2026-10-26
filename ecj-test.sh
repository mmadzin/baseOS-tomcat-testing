#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

#The script expects to have superuser rights

TOMCAT_PACKAGE="tomcat"

usage() {
    echo "Usage: $(basename "$0") [-p PACKAGE] [-s STREAM] [-h]"
    echo ""
    echo "Options:"
    echo "  -p PACKAGE   Tomcat package name to install (default: tomcat)"
    echo "  -s STREAM    RHEL stream (e.g. RHEL-9.6.0.Z.EUS, RHEL-9.6.0.Z.E4S)"
    echo "  -h           Show this help message and exit"
    exit 0
}

while getopts ":p:s:h" option; do
    case "${option}" in
        p) TOMCAT_PACKAGE="${OPTARG}" ;;
        s) STREAM="${OPTARG}" ;;
        h) usage ;;
        :) echo "Error: -${OPTARG} requires an argument." >&2; exit 1 ;;
        *) echo "Error: Invalid option -${OPTARG}." >&2; exit 1 ;;
    esac
done

# 1. Load the OS variables
. /etc/os-release

# 2. Store the major version in a variable named RHEL_VER
RHEL_VER=${VERSION_ID%%.*}

URL="https://rhsm-pulp.corp.stage.redhat.com/content"
DIST="dist"

if [[ "$STREAM" =~ "EUS" ]]; then
        DIST="eus"
fi

if [[ "$STREAM" =~ "E4S" ]] || [[ "$STREAM" =~ "E2S" ]]; then
        DIST="e4s"
fi

URL="${URL}/${DIST}/"

if [ -z "$STREAM" ]; then
        URL="${URL}rhel${RHEL_VER}/${RHEL_VER}/x86_64/appstream/os/"
else
        # Extract the versions from stream e.g. RHEL-9.6.0.Z.EUS
        CLEAN_VER="${STREAM#*-}" # Removes everything up to the first hyphen ("9.6.0.Z.EUS")

        MAJOR_VER=$(echo "$CLEAN_VER" | cut -d'.' -f1) # Extracts "9"
        MINOR_VER=$(echo "$CLEAN_VER" | cut -d'.' -f1-2) # Extracts "9.6"

        URL="${URL}rhel${MAJOR_VER}/${MINOR_VER}/x86_64/appstream/os/"
fi

echo "[stage]" > /etc/yum.repos.d/stage.repo
echo "name=stage" >> /etc/yum.repos.d/stage.repo
echo "baseurl=${URL}" >> /etc/yum.repos.d/stage.repo
echo "enabled=1" >> /etc/yum.repos.d/stage.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/stage.repo

echo "Installing Tomcat and curl..."
dnf update -y
dnf install -y ${TOMCAT_PACKAGE}
dnf install curl

echo "Setting up web application directory..."
WEBAPP_DIR="/var/lib/tomcat/webapps/ROOT"
mkdir -p "$WEBAPP_DIR"

echo "Deploying test-ecj.jsp..."
cat << 'EOF' > "$WEBAPP_DIR/test-ecj.jsp"
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>ECJ Library Test</title>
</head>
<body>
    <h2>JSP Engine & ECJ Load Test</h2>
    <div class="box">
        <p><strong>1. JSP Compilation Status:</strong> <span class="success">SUCCESS</span></p>
        <hr>
        <p><strong>2. ECJ Library Status:</strong> 
        <%
            boolean isEcjLoaded = false;
            try {
                Class.forName("org.eclipse.jdt.internal.compiler.Compiler");
                isEcjLoaded = true;
            } catch (ClassNotFoundException e) {
                isEcjLoaded = false;
            }
        %>
        <% if (isEcjLoaded) { %>
            <span class="success">LOADED</span></p>
        <% } else { %>
            <span class="fail">NOT_FOUND</span></p>
        <% } %>
    </div>
</body>
</html>
EOF

echo "Setting permissions for Tomcat user..."
chown -R tomcat:tomcat "$WEBAPP_DIR"

echo "Opening port 8080 in firewalld (if active)..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --add-port=8080/tcp --permanent
    firewall-cmd --reload
fi

echo "Enabling and starting Tomcat service..."
systemctl enable --now tomcat

echo "======================================================"
echo "Starting Verification..."
echo "======================================================"

URL="http://localhost:8080/test-ecj.jsp"
MAX_RETRIES=15
WAIT_TIME=2
RETRY_COUNT=0

echo "Waiting for Tomcat to initialize and compile the JSP (this may take a few seconds)..."

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Fetch the page silently, output HTTP status code, and save HTML body to a temp file
    HTTP_STATUS=$(curl -s -o /tmp/ecj_test_output.html -w "%{http_code}" "$URL")
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e "\n[HTTP 200 OK] Server responded successfully."
        break
    elif [ "$HTTP_STATUS" -eq 500 ]; then
        echo -e "\n❌ [HTTP 500 ERROR] JSP compilation failed! ECJ is likely missing or broken."
        cat /tmp/ecj_test_output.html
        exit 1
    fi
    
    echo -n "."
    sleep $WAIT_TIME
    RETRY_COUNT=$((RETRY_COUNT+1))
done

# Check if we timed out
if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "\n❌ ERROR: Tomcat did not become available in time (Timeout)."
    exit 1
fi

# Verify the specific output in the HTML
if grep -q "LOADED" /tmp/ecj_test_output.html; then
    echo -e "✅ TEST PASSED: The ECJ Library is successfully loaded in the server classpath!"
    rm -f /tmp/ecj_test_output.html
    exit 0
else
    echo -e "❌ TEST FAILED: The JSP rendered, but the ECJ classes were NOT FOUND."
    echo "Check if ecj.jar is actually linked inside Tomcat's lib directory."
    rm -f /tmp/ecj_test_output.html
    exit 1
fi
