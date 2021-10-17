## All Day DevOps 2021 

## Talk Title :- less risky business way to reduce cloud native provisioning issues 

Slides 


## Demo -1 
![](https://raw.githubusercontent.com/sangam14/alldaydevops2021/main/kops-terraform-terrascan.drawio.svg)


## Requirements
* [Terraform](https://www.terraform.io/downloads.html)
* [Kops](https://github.com/kubernetes/kops#installing)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Terrascan](https://github.com/accurics/terrascan)

## Install Terrascan 

Native Way
```
$ curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E "https://.+?_Darwin_x86_64.tar.gz")" > terrascan.tar.gz
$ tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz
$ install terrascan /usr/local/bin && rm terrascan
$ terrascan
```

via brew 
```
$ brew install terrascan

```
## Clone This Repo 

step 1: clone 
```
git clone https://github.com/sangam14/alldaydevops2021
```
step 2: change dir 

```
cd kops-terraform-terrascan
```
step 3 : scan terraform 
```
terrascan scan -t aws -i terraform
```
Violation Details -

```
    
        Description    :        Ensure VPC flow logging is enabled in all VPCs
        File           :        kops-terraform-terrascan/modules/vpc/main.tf
        Module Name    :        network
        Plan Root      :        kops-terraform-terrascan
        Line           :        5
        Severity       :        LOW
        -----------------------------------------------------------------------

        Description    :        Ensure VPC flow logging is enabled in all VPCs
        File           :        kops-terraform-terrascan/modules/vpc/main.tf
        Module Name    :        root
        Plan Root      :        kops-terraform-terrascan/modules/vpc
        Line           :        5
        Severity       :        LOW
        -----------------------------------------------------------------------


Scan Summary -

        File/Folder         :   /Users/sangam/Documents/GitHub/alldaydevops2021
        IaC Type            :   terraform
        Scanned At          :   2021-10-16 23:39:12.157608 +0000 UTC
        Policies Validated  :   2
        Violated Policies   :   2
        Low                 :   2
        Medium              :   0
        High                :   0


```

## apply remediation for above violation details 

enable VPC flow logging : flow log records that capture specific traffic flows.

add resource under VPC module
```

 resource "aws_flow_log" "vpc" {
 iam_role_arn    = "arn"
  log_destination = "log"
 traffic_type    = "ALL"
   vpc_id          = "${aws_vpc.vpc.id}"
}

```

Scan again 

```

terrascan scan -t aws -i terraform

Scan Summary -

        File/Folder         :   /Users/sangam/Documents/GitHub/alldaydevops2021
        IaC Type            :   terraform
        Scanned At          :   2021-10-16 23:44:55.626183 +0000 UTC
        Policies Validated  :   2
        Violated Policies   :   0
        Low                 :   0
        Medium              :   0
        High                :   0


```



## Ready to Deploy the environment ! 

1. Create a `backend.tf` file from `backend.tf.example` and fill the missing values.
```
cp backend.tf.example backend.tf
```
2. Create a config file for your environment by copying `config/env.tfvars.example` and fill the missing values
```
cp config/env.tfvars.example <env_name>.tfvars
```
3. Execute `terraform init`, if successful your output should look like this

```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
4. Execute `terraform plan -var-file=config/env.tfvars`

```
Plan: 27 to add, 1 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

Releasing state lock. This may take a few moments...
```
5. Execute `terraform apply -var-file=config/env.tfvars` and answer `yes` when prompted.
```
Apply complete! Resources: 27 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...
```
6. Once terraform is done you can check the state of the cluster with:
```
export KOPS_STATE_STORE=s3://<kops_state_bucket> # Get this values from config/<env_name>.tfvars
kops export kubecfg --admin --name <name>.<hosted_zone>
kops validate cluster
```
7. After kops reports your cluster as valid you can start running kubectl commands:

```
Using cluster from kubectl context: <name>.<hosted_zone>

Validating cluster <name>.<hosted_zone>

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
agent			Node	t3.medium	1	2	PrivateSubnet-0,PrivateSubnet-1,PrivateSubnet-2
master-us-west-2a	Master	t3.medium	1	1	PrivateSubnet-0
master-us-west-2b	Master	t3.medium	1	1	PrivateSubnet-1
master-us-west-2c	Master	t3.medium	1	1	PrivateSubnet-2

NODE STATUS
NAME						ROLE	READY
ip-10-2-2-68.us-west-2.compute.internal		master	True
ip-10-2-3-217.us-west-2.compute.internal	master	True
ip-10-2-3-218.us-west-2.compute.internal	node	True
ip-10-2-4-251.us-west-2.compute.internal	master	True

Your cluster <name>.<hosted_zone> is ready
```
8. For example `kubectl get nodes` should output something like this:
```
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-2-2-68.us-west-2.compute.internal    Ready    master   5m    v1.11.9
ip-10-2-3-217.us-west-2.compute.internal   Ready    master   5m    v1.11.9
ip-10-2-3-218.us-west-2.compute.internal   Ready    node     4m    v1.11.9
ip-10-2-4-251.us-west-2.compute.internal   Ready    master   5m    v1.11.9
```
9. To destroy the environment simply run `terraform destroy -var-file=config/env.tfvars` and answer `yes` when prompted.
10. To manually destroy the cluster run `kops delete cluster <name>.<hosted_zone> --yes`


## Demo -2 

## Secure your Web App before deploy using Docker/kubernetes/Helm application - think about security ! 



