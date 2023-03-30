# Terraform/Proxmox/Flux Framework

Terraform infrastructure as code framework for building a proxmox based k3s cluster with flux and a catalog of pre-integrated applications. We have tried to make this repo as simple as possible to configure, using a single variable/secrets file per application or stage of install.

## Repo Layout

The repo is laid out in 3 sections:

```
├── k8s
│   └── apps
│   └── bootstrap
│   └── config
├── proxmox-image-build
│   └── cloud
│   └── config
└── terraform-build
    └── config
```

**proxmox-image-build** - Scripts required to build a light weight ubuntu cloud-init image with your customisations
2. terraform-build - Terraform configs required to create VM's on Proxmox using the image created by the image build step, upload your SSH keys, run checks on the OS and install K3S on each VM.
3. k8s - Flux configurations for all applications in the application catalogue.

Each of these directories will contain a "config" directory which should be the only place you need to go to configure the whole solution.

## Install Instructions

* Fork this repo
* Proxmox Base Image
    * Configure Image Options
    * Build Image
    * Upload to Proxmox Server
* Configure GitHub
    * Token
    * Username
* Configure Proxmox
    * API User
    * API Token
    * API URL
    * API Permissions
* Configure K3S
    * Cluster Details
    * Node Roles & Configurations
* Configure Application Catalog
    * Secrets for each application
    * Variables for each application
* Install Terraform
* Run Terraform