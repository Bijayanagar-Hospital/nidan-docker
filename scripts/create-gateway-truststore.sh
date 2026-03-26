#!/usr/bin/env bash
# Build a PKCS#12 truststore for CIS when calling HTTPS gateways (e.g. OpenELIS).
# Default JVM trustStorePassword in dev examples: gatewayTrust123
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT="${1:-${REPO_DOCKER_DIR}/gateway-truststore.p12}"
DEST_PASS="${GATEWAY_TRUSTSTORE_PASSWORD:-gatewayTrust123}"

JAVA_HOME="${JAVA_HOME:-}"
if [[ -z "${JAVA_HOME}" ]] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  JAVA_HOME="$(/usr/libexec/java_home)"
fi
if [[ -z "${JAVA_HOME}" ]]; then
  echo "Set JAVA_HOME or install a JDK." >&2
  exit 1
fi

CACERTS="${JAVA_HOME}/lib/security/cacerts"
if [[ ! -f "${CACERTS}" ]]; then
  echo "Missing cacerts at ${CACERTS}" >&2
  exit 1
fi

if [[ -d "${OUT}" ]]; then
  echo "Removing directory placeholder at ${OUT}" >&2
  rmdir "${OUT}" 2>/dev/null || rm -rf "${OUT}"
fi

TMP="$(mktemp -u).p12"
# Java 17+ cacerts are often PKCS12; try PKCS12 first, then JKS.
if keytool -importkeystore -noprompt \
  -srckeystore "${CACERTS}" -srcstoretype PKCS12 -srcstorepass changeit \
  -destkeystore "${TMP}" -deststoretype PKCS12 -deststorepass "${DEST_PASS}" 2>/dev/null; then
  :
elif keytool -importkeystore -noprompt \
  -srckeystore "${CACERTS}" -srcstoretype JKS -srcstorepass changeit \
  -destkeystore "${TMP}" -deststoretype PKCS12 -deststorepass "${DEST_PASS}"; then
  :
else
  echo "keytool could not read ${CACERTS} (try: srcstorepass may not be changeit on this JDK)." >&2
  rm -f "${TMP}"
  exit 1
fi

mv "${TMP}" "${OUT}"
echo "Wrote ${OUT} (password: ${DEST_PASS})"
