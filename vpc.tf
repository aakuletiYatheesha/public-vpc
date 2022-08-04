
terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}
variable "ssh_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLddEgArugfn+VWc9psgpOhu5yi4/7SCM5o+Fu1goDS9tlHn9Hij2WFXLU1GqYsxHh+14JrSWwLDF6e7ZobkpQPII0feSQsrn1MR3mkE6tZ1y9QhvKw5F+m08jzrP+zwQk8JkIkYu+IO0q7AoP7PuA5EaGmpC78hwNscT65ofH8gxEzPRe2A/9gU46z03Wf8klrL0G3r2NR5EVMsdMZWwv52y3D1qwSbRAU5fD7DO3l+yuCQ1KLHg1ZZF8Cf/y2O+s6C1b2dJBnH5gq7EElxCobl75+zXL0Ue9B5Q1MJIkpdaMMN+3ZxFtdC0xU9WarOceUVGuVS5zbba2OGnsAfTW526Z1Zgmal8bTh/xCvkZtMCkxi806/rDJACnVIi4ukMtxB2orgIENCl1iHzLsRSczSkRtHy9+SUyu+ZBX25OYKr3ak3JHBwOMqCV7yL2a5FqPoWYGfc+xdTZ7cI3BhEZUxKOjkVPN1VrCPr8I5MNChKy7R9wnuVLfyTUg33gVc4xFLPZCHYncbRDs+1VZ7QoyrwC5usMv0rzp3vA8YHgX63Fbcwv3x2m0Pqa6XJnsD5e+MmRJwsf0f5KMCpk6gu6xG/dAxqjxjd/idKzfyniHcQlqfVQM6oOUX120ON89jMRQhqWnOrRhWSvXd0T4SfDM2MeMqa+ZYmINradOjSEMw== aakuletiyatheesha"
}

variable "ibmcloud_api_key" {
    default =  "jJxxOWYGhqAdlH2Cun1Q8JwxLIcFTKcY19tEfRgtzGjw"
}
provider "ibm" {
    ibmcloud_api_key   = var.ibmcloud_api_key
    region     = "eu-de"
   
   
 }
 
locals {
    BASENAME = "vpcmyvpc"
     ZONE     = "eu-de-1"
}
resource "ibm_is_vpc" "vpc" {
    name = "${local.BASENAME}-vpc"
    resource_group = "d0bb7c6f73be499599e27b54a0be9cae"
    //region     = "Frankfurt"
}
resource "ibm_is_security_group" "sg1" {
    name = "${local.BASENAME}-sg1"
    vpc  = ibm_is_vpc.vpc.id
     resource_group = "d0bb7c6f73be499599e27b54a0be9cae"
}
# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
    group     = ibm_is_security_group.sg1.id
    direction = "inbound"
    remote    = "0.0.0.0/0"
    tcp {
      port_min = 22
      port_max = 22
    }
}
resource "ibm_is_subnet" "subnet" {
    name                     = "${local.BASENAME}subnet"
    resource_group           = "d0bb7c6f73be499599e27b54a0be9cae"
    vpc                      = ibm_is_vpc.vpc.id
    zone                     =  local.ZONE
    //region                   = "Frankfurt"
    total_ipv4_address_count = 256 
}

data "ibm_is_image" "centos" {
    name = "ibm-centos-7-6-minimal-amd64-1"
}
data "ibm_is_ssh_key" "ssh_key_id" {
    name = "yathissh"
    }
resource "ibm_is_instance" "vsi1" {
    name    = "${local.BASENAME}-vsi1"
    vpc     = ibm_is_vpc.vpc.id
    zone    = local.ZONE
    keys    = [data.ibm_is_ssh_key.ssh_key_id.id] 
    image   = data.ibm_is_image.centos.id
    resource_group           = "d0bb7c6f73be499599e27b54a0be9cae"
    profile = "cx2-2x4"
    primary_network_interface {
        subnet          = ibm_is_subnet.subnet.id
        security_groups = [ibm_is_security_group.sg1.id]
    }
}
resource "ibm_is_floating_ip" "fip1" {
    name   = "${local.BASENAME}-fip1"
    resource_group           = "d0bb7c6f73be499599e27b54a0be9cae"
    target = ibm_is_instance.vsi1.primary_network_interface[0].id
    }
  output "sshcommand" {
    value = "ssh root@${ibm_is_floating_ip.fip1.address}"
    }