#!/bin/bash

# Set the namespace for your application
APP_NAMESPACE="default"
# Set the namespace for the NGINX Ingress Controller
INGRESS_NAMESPACE="ingress-nginx"

# Function to print a section header
print_header() {
  echo "----------------------------------------"
  echo "$1"
  echo "----------------------------------------"
}

# Function to check pod status and print logs
check_pod_status() {
  local namespace=$1
  local deployment=$2

  print_header "Checking Pods for Deployment: $deployment in namespace: $namespace"

  pods=$(kubectl get pods -n $namespace -l app.kubernetes.io/instance=$deployment -o jsonpath='{.items[*].metadata.name}')
  for pod in $pods; do
    status=$(kubectl get pod $pod -n $namespace -o jsonpath='{.status.phase}')
    echo "Pod: $pod, Status: $status"
    if [[ "$status" != "Running" ]]; then
      echo "ERROR: Pod $pod is not running."
      kubectl describe pod $pod -n $namespace
      kubectl logs $pod -n $namespace 2>&1
    fi
  done
}

# Function to check service status
check_service_status() {
  local namespace=$1
  local service=$2

  print_header "Checking Service: $service in namespace: $namespace"

  kubectl get service $service -n $namespace -o wide
  type=$(kubectl get service $service -n $namespace -o jsonpath='{.spec.type}')
  if [[ "$type" == "LoadBalancer" ]]; then
    external_ip=$(kubectl get service $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[*].ip}')
    if [[ -z "$external_ip" ]]; then
      echo "WARNING: LoadBalancer service $service does not have an external IP yet."
    else
      echo "INFO: LoadBalancer service $service has external IP: $external_ip"
    fi
  else
    echo "INFO: Service $service is of type $type (no external IP expected)."
  fi
}

# Function to check ingress status
check_ingress_status() {
  local namespace=$1
  local ingress=$2

  print_header "Checking Ingress: $ingress in namespace: $namespace"

  kubectl get ingress $ingress -n $namespace -o wide
  hosts=$(kubectl get ingress $ingress -n $namespace -o jsonpath='{.spec.rules[*].host}')
  addresses=$(kubectl get ingress $ingress -n $namespace -o jsonpath='{.status.loadBalancer.ingress[*].ip}')

  if [[ -z "$addresses" ]]; then
    echo "WARNING: Ingress $ingress does not have an assigned IP address yet."
  else
    echo "INFO: Ingress $ingress is mapped to:"
    for i in $(seq 0 $((${#hosts[@]}-1))); do
      echo "  - Host: ${hosts[$i]}, Address: ${addresses[$i]}"
    done
  fi
}

# Function to check NGINX Ingress Controller logs
check_nginx_logs() {
  local namespace=$1

  print_header "Checking NGINX Ingress Controller Logs in namespace: $namespace"

  pods=$(kubectl get pods -n $namespace -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].metadata.name}')
  for pod in $pods; do
    echo "Logs for pod: $pod"
    kubectl logs $pod -n $namespace 2>&1
    echo ""
  done
}

# Function to check events in a namespace
check_events() {
  local namespace=$1

  print_header "Checking Events in namespace: $namespace"

  kubectl get events -n $namespace
}

# Function to describe a resource
describe_resource() {
  local namespace=$1
  local resource_type=$2
  local resource_name=$3

  print_header "Describing $resource_type: $resource_name in namespace: $namespace"

  kubectl describe $resource_type $resource_name -n $namespace
}

# --- Main Script Execution ---

# Check NGINX Ingress Controller
check_pod_status $INGRESS_NAMESPACE "ingress-nginx"
check_service_status $INGRESS_NAMESPACE "nginx-ingress-controller"
check_nginx_logs $INGRESS_NAMESPACE

# Check your application
check_pod_status $APP_NAMESPACE "myapp"
check_service_status $APP_NAMESPACE "myapp-service"
check_ingress_status $APP_NAMESPACE "myapp-ingress"

# Check events in both namespaces
check_events $INGRESS_NAMESPACE
check_events $APP_NAMESPACE

# Example of how to describe a specific resource
describe_resource $APP_NAMESPACE "deployment" "myapp"
