#!/bin/bash

NAMESPACE="ingress-nginx"
DEPLOYMENT="nginx-ingress-controller"
SERVICE_NAME="nginx-ingress-controller"
TARGET_PORT=10254

echo "----------------------------------------"
echo "Checking Network Policies in namespace: $NAMESPACE"
echo "----------------------------------------"
NETWORK_POLICIES=$(kubectl get networkpolicy -n $NAMESPACE --no-headers 2>/dev/null)
if [[ -z "$NETWORK_POLICIES" ]]; then
    echo "No network policies found in namespace: $NAMESPACE"
else
    echo "Found the following network policies:"
    echo "$NETWORK_POLICIES"
    echo "Describing network policies..."
    for policy in $(kubectl get networkpolicy -n $NAMESPACE -o name); do
        echo "----------------------------------------"
        echo "Describing $policy in namespace: $NAMESPACE"
        kubectl describe "$policy" -n $NAMESPACE
    done
fi

echo "----------------------------------------"
echo "Checking RBAC Configuration for NGINX Ingress in namespace: $NAMESPACE"
echo "----------------------------------------"
RBAC_BINDINGS=$(kubectl get clusterrolebinding,rolebinding -A --no-headers | grep nginx-ingress)
if [[ -z "$RBAC_BINDINGS" ]]; then
    echo "No RBAC bindings found for NGINX Ingress controller."
else
    echo "Found the following RBAC bindings:"
    echo "$RBAC_BINDINGS"
    echo "Describing RBAC bindings..."
    for binding in $(kubectl get clusterrolebinding,rolebinding -A -o name | grep nginx-ingress); do
        echo "----------------------------------------"
        echo "Describing $binding"
        kubectl describe "$binding"
    done
fi

echo "----------------------------------------"
echo "Checking if service $SERVICE_NAME exists in namespace: $NAMESPACE"
echo "----------------------------------------"
SERVICE=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE --ignore-not-found)
if [[ -z "$SERVICE" ]]; then
    echo "Service $SERVICE_NAME not found in namespace: $NAMESPACE"
else
    echo "Service $SERVICE_NAME found in namespace: $NAMESPACE"
    kubectl describe svc $SERVICE_NAME -n $NAMESPACE
fi

echo "----------------------------------------"
echo "Checking NGINX Ingress Controller Pods in namespace: $NAMESPACE"
echo "----------------------------------------"
PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --no-headers)
if [[ -z "$PODS" ]]; then
    echo "No NGINX Ingress controller pods found in namespace: $NAMESPACE"
else
    echo "Found the following NGINX Ingress controller pods:"
    echo "$PODS"
    echo "Describing pod status and checking logs for readiness issues..."
    for pod in $(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx -o name); do
        echo "----------------------------------------"
        echo "Describing $pod in namespace: $NAMESPACE"
        kubectl describe "$pod" -n $NAMESPACE

        echo "Checking logs for $pod"
        kubectl logs "$pod" -n $NAMESPACE

        echo "Checking readiness probe status for $pod"
        kubectl exec "$pod" -n $NAMESPACE -- curl -s http://localhost:$TARGET_PORT/healthz || echo "Readiness probe failed for pod $pod"
    done
fi

echo "----------------------------------------"
echo "Checking Events in namespace: $NAMESPACE"
echo "----------------------------------------"
kubectl get events -n $NAMESPACE --sort-by='.metadata.creationTimestamp'

echo "----------------------------------------"
echo "Checking NGINX Ingress Health Status"
echo "----------------------------------------"
INGRESS_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [[ -z "$INGRESS_IP" ]]; then
    echo "NGINX Ingress service does not have an external IP yet."
else
    echo "NGINX Ingress External IP: $INGRESS_IP"
    echo "Checking health status..."
    curl -s http://$INGRESS_IP:$TARGET_PORT/healthz || echo "Failed to reach health endpoint."
fi

echo "----------------------------------------"
echo "Script completed. Please check the output above for any issues."
