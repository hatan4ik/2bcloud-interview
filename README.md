# 2bcloud interview: AKS + Node.js + Key Vault
This repository **does** spin up Kubernetes and deploy an application. Terraform stands up Azure networking, Key Vault, ACR, and an AKS cluster, builds the provided Node.js app into a container image, pushes it to ACR, installs NGINX ingress via Helm, and deploys the app with a Service and Ingress.

## What this deploys
- Azure Virtual Network plus subnets, NSGs, and route tables (see `terraform.tfvars`).
- Key Vault and an ACR-specific Azure AD service principal; its credentials are stored as secret `acr-sp-secret` in the vault.
- ACR (admin disabled) and AKS (Azure CNI, system-assigned identity, RBAC). Role assignments allow AKS to pull from ACR and read Key Vault secrets.
- Static public IP and Helm-installed `ingress-nginx` in namespace `myapp` (currently annotated as an internal load balancer).
- Docker image built with `az acr build` from this repo (tag read from `image_tag.txt`), pushed to ACR, and deployed as a Deployment/Service/Ingress in namespace `myapp`.

## High-level architecture
```
Dev laptop (terraform apply, az CLI auth)
    |
    v
Azure RG
  ├─ VNet + subnets + NSGs + route tables
  ├─ Key Vault (holds acr-sp-secret)
  ├─ AAD App/SP for ACR auth
  ├─ ACR (admin disabled)
  ├─ Static Public IP
  └─ AKS (Azure CNI, system MI)
       ├─ Role: AcrPull, KV Secrets User
       ├─ helm_release ingress-nginx (LB -> static IP)
       └─ myapp namespace
            ├─ imagePullSecret (ACR SP)
            ├─ Deployment (Express/Helmet on :3000)
            ├─ Service (ClusterIP :80 -> 3000)
            └─ Ingress (host: myapp.yourdomain.com)
```

Request path: User → DNS host → static IP → ingress-nginx → Service → Pod. `/secret` calls Key Vault using `DefaultAzureCredential` + `KEY_VAULT_URL`.

## Application
- `index.js` is an Express server with Helmet. Endpoints:
  - `/` → “Hello World!”
  - `/secret` → reads secret `my-secret` from Key Vault via `DefaultAzureCredential`.
- Requires env var `KEY_VAULT_URL` (e.g., `https://<kv-name>.vault.azure.net/`). The Deployment does not set this automatically—set it before hitting `/secret`.
- Listens on port `3000`; Kubernetes Service exposes it on port `80`.

## Prerequisites
- Azure subscription and an existing resource group (referenced by `resource_group_name` in `terraform.tfvars`).
- Terraform ≥ 1.x, `az` CLI logged in with rights to create the listed resources, and `jq` (used in the image build step). `kubectl`/`helm` are helpful for verification.
- Optional: `npm install` if you want to run the app locally; `KEY_VAULT_URL` must be set for `/secret`.

## Configure
- Update `terraform.tfvars` with your subscription, tenant, location, resource group, VNet/subnet layouts, AKS sizing, and ingress host (change `myapp.yourdomain.com` in `kubernetes_ingress_v1.myapp_ingress` in `main.tf`).
- Set your desired image tag in `image_tag.txt` (default: `ef5f01d`).
- Create secret `my-secret` in the provisioned Key Vault with the value you want `/secret` to return.
- Decide whether the ingress should be internal or public; current Helm values include both a static public IP and an internal load balancer annotation—adjust as needed.
- Ensure the pod has `KEY_VAULT_URL` (e.g., `kubectl -n myapp set env deployment/myapp KEY_VAULT_URL=https://<kv>.vault.azure.net/` or add an env block in `kubernetes_deployment.myapp`).

## Deploy (Terraform)
```bash
terraform init
terraform plan
terraform apply
```
Terraform state is **not committed**; configure a remote backend for team use. The Kubernetes provider is wired to the created AKS cluster via the generated kubeconfig.

## Access the app
1. After apply, fetch the ingress IP/host:
   ```bash
   kubectl get ingress -n myapp
   ```
2. Point DNS (or `/etc/hosts`) for your chosen host to the ingress IP.
3. Call `http://<host>/` for the root endpoint and `http://<host>/secret` after setting `KEY_VAULT_URL` and creating the `my-secret` secret.

## Utilities
- Troubleshooting helpers live in `scripts/` (e.g., `debug-aks-network.sh`, `monitor.sh`). `aks-debug.sh` is aimed at cert-manager/ingress debugging.

## Key decisions to finalize
- Ingress exposure: keep public static IP or make it internal; update service annotations and DNS/host accordingly.
- Inject `KEY_VAULT_URL` into the Deployment (env/Secret/ConfigMap) so `/secret` works out of the box.
- Keep `.terraform/` and all `tfstate` files out of git; use a remote backend and short-lived local caches.

## Cleanup
Destroy everything with:
```bash
terraform destroy
```
