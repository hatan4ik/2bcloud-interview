#!/bin/bash

# Usage: ./troubleshoot-cert-manager.sh <namespace> <release_name>
# Example: ./troubleshoot-cert-manager.sh cert-manager cert-manager-your-prefix

# Set namespace and release name from input parameters, with defaults if not provided
NAMESPACE="${1:-cert-manager}"
RELEASE_NAME="${2:-cert-manager-release}"

# Directory for logs
LOG_DIR="./cert-manager-troubleshoot-logs"
mkdir -p "$LOG_DIR"

# Logging function for consistent output
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/troubleshoot.log"
}

log "Starting troubleshooting for cert-manager in namespace: $NAMESPACE, release: $RELEASE_NAME"

# Get Kubernetes events
log "Gathering events in the namespace $NAMESPACE..."
kubectl get events -n "$NAMESPACE" > "$LOG_DIR/events.log" 2>&1

# Get pod status and logs
log "Collecting pod information and logs..."
kubectl get pods -n "$NAMESPACE" -o wide > "$LOG_DIR/pods-status.log" 2>&1
for pod in $(kubectl get pods -n "$NAMESPACE" -o name); do
    log "Fetching logs for pod $pod..."
    kubectl logs "$pod" -n "$NAMESPACE" > "$LOG_DIR/${pod#*/}-logs.log" 2>&1
done

# Get Helm release status
log "Checking Helm release status for $RELEASE_NAME..."
helm status "$RELEASE_NAME" -n "$NAMESPACE" > "$LOG_DIR/helm-status.log" 2>&1

# Additional information: Deployment and Service descriptions
log "Describing deployments and services..."
kubectl describe deployments -n "$NAMESPACE" > "$LOG_DIR/deployments-description.log" 2>&1
kubectl describe services -n "$NAMESPACE" > "$LOG_DIR/services-description.log" 2>&1

# Final log message
log "Troubleshooting logs collected in $LOG_DIR"
