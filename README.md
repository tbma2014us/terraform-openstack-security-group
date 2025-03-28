# Terraform OpenStack Security Group Module
## Rewritten for Terraform 1.8+

Terraform module, which creates security groups on OpenStack.

## Features

This module aims to implement many combinations of arguments supported by OpenStack and the latest stable version of Terraform:

* Full control of security group rules if needed.
* Ingress and egress rule blocks for convenience.
* Support to separate IPv4 and IPv6 rules in different lists.

## Terraform versions

Terraform 1.8.0

## Usage

There are several ways to use this module but here are two examples below:

### Ingress/Egress rule blocks

The `ingress_rules` and `egress_rules` blocks let you define and separate these rules in different lists, which might be useful in some situations. Values for the defined keys are limited to what is described in the documentation for [OpenStack Neutron Security Group Rule v2](https://www.terraform.io/docs/providers/openstack/r/networking_secgroup_rule_v2.html):

| Key | Description | Example |
| --- | --- | ---|
| description | A description of the rule. | `HTTP` |
| protocol | The layer 4 protocol type. | `tcp` |
| port_range_min | The lower part of the allowed port range. | `8080` |
| port_range_max | The higher part of the allowed port range. | `8081` |
| port | One port instead of range. Overrides `port_range_min`and `port_range_max`. | `80` |
| remote_ip_prefix | The remote CIDR. | `0.0.0.0/0` |
| remote_group_id | The remote group id. If the same group ID shall be referenced, then write `@self` | `@self` |

```hcl
module "ingress_egress_rules_sg" {
  source      = "haxorof/security-group/openstack"
  name        = "ingress-egress-rules-sg"
  description = "Security group that allows inbound VRRP within the group (IPv4), HTTPS/HTTP open for any (IPv4+IPv6)."

  ingress_rules = [
    { description = "HTTPS", protocol = "tcp", port = 443 },
    { description = "HTTP", protocol = "tcp", port = 80 },
  ]

  ingress_rules_ipv4 = [
    { description = "VRRP", protocol = "vrrp", remote_group_id = "@self" },
  ]

  egress_rules_ipv4 = [
    { description = "VRRP", protocol = "vrrp", remote_group_id = "@self" },
  ]
}
```

### Rule blocks

`rules` block is the most raw form but also gives you the most flexibility. Values for the defined keys are limited to what is described in the documentation for [OpenStack Neutron Security Group Rule v2](https://www.terraform.io/docs/providers/openstack/r/networking_secgroup_rule_v2.html):

| Key | Description | Example |
| --- | --- | ---|
| description | A description of the rule. | `HTTP` |
| direction | The direction of the rule. | `ingress` |
| protocol | The layer 4 protocol type. | `tcp` |
| port_range_min | The lower part of the allowed port range. | `8080` |
| port_range_max | The higher part of the allowed port range. | `8081` |
| port | One port instead of range. Overrides `port_range_min`and `port_range_max`. | `80` |
| remote_ip_prefix | The remote CIDR. | `0.0.0.0/0` |
| remote_group_id | The remote group id. If the same group ID shall be referenced, then write `@self` | `@self` |

```hcl
module "raw_rules_sg" {
  source      = "haxorof/security-group/openstack"
  name        = "raw-rules-sg"
  description = "Security group that allows inbound VRRP within the group (IPv4), HTTPS/HTTP open for any (IPv4+IPv6)."

  rules = [
    { description = "HTTPS", direction = "ingress", protocol = "tcp", port = 443 },
    { description = "HTTP", direction = "ingress", protocol = "tcp", port = 80 },
  ]

  rules_ipv4 = [
    { description = "VRRP", direction = "ingress", protocol = "vrrp", remote_group_id = "@self" },
    { description = "VRRP", direction = "egress", protocol = "vrrp", remote_group_id = "@self" },
  ]
}
```

## Examples

* [Mixed Security Group examples](https://github.com/haxorof/terraform-openstack-security-group/blob/master/examples/mixed)

## License

This is an open-source project under the [MIT](https://github.com/haxorof/terraform-openstack-security-group/blob/master/LICENSE) license.


[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
