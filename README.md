# Redis Enterprise / Hazelcast - Terraforming on GCP

## About

<img width=150
    src="https://redislabs.com/wp-content/themes/wpx/assets/images/logo-redis.svg"
    alt="Read more about Redis Enterprise" />

- Docs <https://docs.redislabs.com/latest/rs/>
- Provided by Redis - <https://redis.com/redis-enterprise-software/overview/>

## Assumption

- gcloud ssh working with `~/.ssh/google_compute_engine` private key
- with public key as `~/.ssh/google_compute_engine.pub`
- GCP IAM / service account exist, with `Compute Admin` and `DNS Administrator` roles
- GCP IAM service account exported `json` in current folder
- terraform

Last used with: Terraform v1.1.7

## Setup

- `terraform init`
- (optional) use a `terraform.tfvars` to override variable like those two important one or those that have no default:

```ini
yourname="testingthis"
credentials="GCP IAM key file.json"
```

- review `variable.tf` to learn what you can override in your `terraform.tfvars`
  - configure number of nodes and admin email
  - review/change as needed
  - configure the name of the json credentials file if needed

Here is an example file

```ini
yourname="..."
clustersize=1
machine_type = "e2-highmem-8" # 8 vCPU, 64 GB
# defaults to e2-standard-2 (2 vCPU, 8 GB)

## defaults to false
# to delete use the cli as terraform destroy seems unreliable
# gcloud container node-pools delete redis-node-pool --cluster avasseur-dev-gke
```

## Usage

```shell
terraform plan
terraform apply
```

will setup GCP, VPC, networks/firewall, DNS for Redis Enterprise and Hazelcast

- node1 will be cluster master
- node2.. will be joining the cluster
- output will show Redis Enterprise cluster ui url and other info
- an admin password will be auto generated
The nodes and cluster are created using external addr and DNS.

```shell
terraform destroy
```

## Important note about the installation process

The Redis Enterprise node VM will be up but most likely the installation script will be running in background for `cluster create` and `cluster join` commands.
You should not try to setup the cluster manually using the Redis Enterprise web UI - but instead you can login using `gcloud compute ssh ...` and explore as user `ubuntu` for traces of the node installation:

```shell
ubuntu@avasseur-dev-1:~$ ls -al
total 56
drwxr-xr-x 2 root   root    4096 Apr 13 22:53 install
-rw-r--r-- 1 root   root     624 Apr 13 22:53 install.log
-rw-r--r-- 1 root   root   14532 Apr 13 22:53 install_rs.log
-rwxr--r-- 1 ubuntu root     129 Apr 13 22:53 node_externaladdr.sh
-rw-r--r-- 1 root   root       2 Apr 13 22:53 node_index.terraform
```

## Stoping & restarting nodes

If you stop the VM and need to restart them:

- you should restart the VM with GCP (Terraform will not do that for you)
- the startup-script will re-run, ignore RS as it is already installed, but update RS node external_addr if the IP changed
Then:
- you must then use `terraform plan` and ``terraform apply` as you external IP addr may have changed. This will update them in the DNS (this may take time for DNS to propagate, ~5min).
- in the meantime you can connect to node1 with the external_addr on https port 8443

## SSH access to the RS nodes (VM instance) with GCP command line

Use `gcloud` with your machine node name that looks like:

```shell
gcloud compute ssh <yourname>-dev-1
```

You can explore logs in `/home/ubuntu` and in `/var/log/syslog` for the startup-script.

## Troubleshooting

If you ssh into a node you can find installation logs:

```shell
sudo su - ubuntu
tail install.log
tail install_RS.log
```

## Known Issues

- if you stopped the VM in GCP, Terraform will assume their external IP are void and will clean up the DNS but will not restart the VM

##  Hazelcast

I have follow the instructions at <https://docs.hazelcast.com/hazelcast/5.2/deploy/deploying-on-gcp>
