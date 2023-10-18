Sample project to provision and destroy an NGINX webserver with Terraform.

#Requirements
- install a local docker VM or desktop

#Steps

1. Initialize the project, which downloads a plugin called a provider that lets Terraform interact with Docker.

> terraform init

2. Provision the NGINX server container with apply. When Terraform asks you to confirm type yes and press ENTER.

> terraform apply

3. Verify the runing instance

> docker ps
> http://localhost:8000