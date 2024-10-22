#!/bin/bash

# Function to check the status of all resources in a namespace
check_namespace_status() {
  local namespace=$1

  echo "----------------------------------------"
  echo "Checking resources in namespace: $namespace"
  echo "----------------------------------------"

  # Check deployments
  echo "Deployments:"
  kubectl get deployments -n $namespace -o wide
  for deployment in $(kubectl get deployments -n $namespace -o name); do
    check_pod_status $namespace $deployment
  done

  echo "" # Add an empty line for better readability

  # Check services
  echo "Services:"
  kubectl get services -n $namespace -o wide
  for service in $(kubectl get services -n $namespace -o name); do
    check_service_status $namespace $service
  done

  echo "" # Add an empty line for better readability

  # Check ingresses
  echo "Ingresses:"
  kubectl get ingresses -n $namespace -o wide
  for ingress in $(kubectl get ingresses -n $namespace -o name); do
    check_ingress_status $namespace $ingress
  done

  echo "----------------------------------------"
  echo "" # Add an empty line for better readability
}

# Function to check pod status and print errors
check_pod_status() {
  local namespace=$1
  local deployment=$2

  # Extract only the deployment name (remove "deployment.apps/")
  deployment_name=$(echo $deployment | awk -F'/' '{print $2}')

  pods=$(kubectl get pods -n $namespace -l app.kubernetes.io/instance=$deployment_name -o jsonpath='{.items[*].metadata.name}')
  for pod in $pods; do
    status=$(kubectl get pod $pod -n $namespace -o jsonpath='{.status.phase}')
    if [[ "$status" != "Running" ]]; then
      echo "ERROR: Pod $pod in namespace $namespace is not running. Status: $status"
      kubectl describe pod $pod -n $namespace
      kubectl logs $pod -n $namespace 2>&1  # Redirect stderr to stdout for logs
    else
      echo "INFO: Pod $pod in namespace $namespace is running."
    fi
  done
}

# Function to check service status and print errors
check_service_status() {
  local namespace=$1
  local service=$2

  type=$(kubectl get service $service -n $namespace -o jsonpath='{.spec.type}') 
  if [[ "$type" == "LoadBalancer" ]]; then
    external_ip=$(kubectl get service $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[*].ip}') 
    if [[ -z "$external_ip" ]]; then
      echo "WARNING: LoadBalancer service $service in namespace $namespace does not have an external IP yet."
    else
      echo "INFO: LoadBalancer service $service in namespace $namespace has external IP: $external_ip"
    fi
  else
    echo "INFO: Service $service in namespace $namespace is of type $type (no external IP expected)."
  fi
}
# Function to check ingress status and print errors
check_ingress_status() {
  local namespace=$1
  local ingress=$2

  hosts=$(kubectl get ingress $ingress -n $namespace -o jsonpath='{.spec.rules[*].host}')
  addresses=$(kubectl get ingress $ingress -n $namespace -o jsonpath='{.status.loadBalancer.ingress[*].ip}')

  if [[ -z "$addresses" ]]; then
    echo "WARNING: Ingress $ingress in namespace $namespace does not have an assigned IP address yet."
  else
    echo "INFO: Ingress $ingress in namespace $namespace is mapped to:"
    for i in $(seq 0 $((${#hosts[@]}-1))); do
      echo "  - Host: ${hosts[$i]}, Address: ${addresses[$i]}"
    done
  fi
}

# Get all namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Check the status of each namespace
for namespace in $namespaces; do
  check_namespace_status $namespace
done
