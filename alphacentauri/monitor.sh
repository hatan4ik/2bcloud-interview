#!/bin/bash

# Set the namespace where the NGINX ingress controller is deployed
NAMESPACE="ingress-nginx"

# Function to get the service name of NGINX Ingress Controller
get_nginx_service_name() {
  kubectl get svc -n "${NAMESPACE}" --no-headers | grep 'nginx' | awk '{print $1}'
}

# Function to monitor the service details
monitor_nginx_service() {
  local service_name=$(get_nginx_service_name)

  if [ -z "$service_name" ]; then
    echo "No NGINX ingress service found in namespace ${NAMESPACE}."
    exit 1
  fi

  echo "Monitoring NGINX Ingress Controller service: ${service_name} in namespace ${NAMESPACE}..."
  kubectl get service -n "${NAMESPACE}" "${service_name}" --output wide --watch
}

# Start monitoring
monitor_nginx_service
