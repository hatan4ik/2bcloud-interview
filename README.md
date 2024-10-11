# 2bcloud-interview



General Points:
1. Create a GitHub Repository for this task.
2. You should create your terraform templates with any code editing tool of your choice. You will be able
to deploy the templates within a dedicated resource group called “Your Name-CANDIDATE_RG”.
 
Task Details:
1. Create and provision the following resources by using Terraform:
- Virtual Machine (VM)
o Ubuntu OS =&gt; Jenkins Server (with docker and git – You can choose if install it via
ansible, local-exec user_data/custom data. But it must be fully automated)
o key vault
o AKS – 1 node pool
- Azure Kubernetes Service (AKS)
o Cert manager - (With external DNS + workload identity)
o azure key vault integration (secret value for your application need to be injected form
the key vault)
o NGINX ingress Controller – (Static IP – when removing Ingress service, the public IP must
remain + use DNS domain name for ingress).
o HPA for CPU and Memory
o Install redis bitnami sentinel on the cluster.
- Azure Container Registry (ACR)
“Terraform apply” should create all above resources with its configuration.
2. Basic Web Application
Write a simple and basic &quot;hello world&quot; web site that presents some content (for example: &quot;Hello
World&quot;) in your preferred language (NodeJs, Python, etc.)
    OR
    Clone an open-source project (any project you want, for example: node hello world)
3. Containerized
- Write a Dockerfile you will use for building an image of the application
- Build an image using the Dockerfile you wrote
- Push the image you built to the ACR
Verification:
o Run the application
o Verify the app is running

4. CI/CD
- Create a Full CI/CD pipeline/s for your application (the application should be deployed on AKS).
- Pay attention, you should create an Optimal and Detailed CI/CD as possible.
5. Orchestration
- You will use the AKS as an orchestration
- By using Jenkins pipelines from previous step, deploy the web application on AKS.
- The application should be accessible over HTTP.
  
Bonus:

Use benchmark tool for the HPA functionality (Like ab) for testing the HPA on you application
pod.