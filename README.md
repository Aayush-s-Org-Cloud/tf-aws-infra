# tf-aws-infra

1. Clone Repository using git clone.
2. Add the Dev and Demo Env files in envs folder.
3. Run Terraform commands on terminal to initialize, plan, apply   and destroy VPCs.

        terraform init
        terraform plan -var-file="envs/___.tfvars"
        terraform apply -var-file="envs/___.tfvars"
        terraform destroy -var-file="envs/____.tfvars"

4. Check on the VPC on AWS console vps will be added/destroyed.