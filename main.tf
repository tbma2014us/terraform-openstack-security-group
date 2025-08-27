terraform {
  required_version = ">= 1.8.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

resource "random_id" "this" {
  count    = var.create && var.use_name_prefix && var.name_prefix == "" ? 1 : 0
  byte_length = 8
}

##################################
# Get ID of created Security Group
##################################
locals {
  this_sg_id = concat(
    openstack_networking_secgroup_v2.this.*.id,
    [""],
  )[
  0
  ]
  this_sg_name = var.use_name_prefix ? (var.name_prefix == "" ? join( "-", [random_id.this[0].hex, var.name]) : join( "-", [var.name_prefix,var.name])): var.name
}


################
# Security group
################
resource "openstack_networking_secgroup_v2" "this" {
  count = var.create && false == var.use_name_prefix ? 1 : 0

  name        = local.this_sg_name
  description = var.description

  tags = var.tags

  delete_default_rules = var.delete_default_rules
  lifecycle {
    create_before_destroy = true
  }
}

######################
# Security group rules
######################
locals {
  ingress_rules_ipv4 = { for r in var.ingress_rules_ipv4 : sha1(jsonencode(r)) => merge(r, { direction = "ingress", ethertype = "IPv4" }) }
  ingress_rules_ipv6 = { for r in var.ingress_rules_ipv6 : sha1(jsonencode(r)) => merge(r, { direction = "ingress", ethertype = "IPv6" }) }
  ingress_rules = merge(local.ingress_rules_ipv4, local.ingress_rules_ipv6)

  ingress_rules_both_ipv6 = { for r in var.ingress_rules : sha1(jsonencode(r)) => merge(r, { direction = "ingress", ethertype = "IPv6" }) }
  ingress_rules_both_ipv4 = { for r in var.ingress_rules : sha1(jsonencode(r)) => merge(r, { direction = "ingress", ethertype = "IPv4" }) }
  ingress_rules_both = merge(local.ingress_rules_both_ipv4, local.ingress_rules_both_ipv6)

  egress_rules_ipv4 = { for r in var.egress_rules_ipv4 : sha1(jsonencode(r)) => merge(r, { direction = "egress", ethertype = "IPv4" }) }
  egress_rules_ipv6 = { for r in var.egress_rules_ipv6 : sha1(jsonencode(r)) => merge(r, { direction = "egress", ethertype = "IPv6" }) }
  egress_rules = merge(local.egress_rules_ipv4, local.egress_rules_ipv6)

  egress_rules_both_ipv6 = { for r in var.egress_rules : sha1(jsonencode(r)) => merge(r, { direction = "egress", ethertype = "IPv6" }) }
  egress_rules_both_ipv4 = { for r in var.egress_rules : sha1(jsonencode(r)) => merge(r, { direction = "egress", ethertype = "IPv4" }) }
  egress_rules_both = merge(local.egress_rules_both_ipv4, local.egress_rules_both_ipv6)

  rules_ipv4 = {for r in var.rules_ipv4 : sha1(jsonencode(r)) =>  merge(r, { ethertype = "IPv4" })}
  rules_ipv6 = {for r in var.rules_ipv6 : sha1(jsonencode(r)) =>  merge(r, { ethertype = "IPv6" })}

  rules_both_ipv4 = {for r in var.rules : sha1(jsonencode(r)) =>  merge(r, { ethertype = "IPv4" })}
  rules_both_ipv6 = {for r in var.rules : sha1(jsonencode(r)) =>  merge(r, { ethertype = "IPv6" })}
  rules_both      = merge(local.rules_both_ipv4, local.rules_both_ipv6)

  rules = merge(local.rules_both, local.rules_ipv4, local.rules_ipv6, local.egress_rules_both, local.egress_rules, local.ingress_rules_both, local.ingress_rules)
}

resource "openstack_networking_secgroup_rule_v2" "rules" {
  for_each          = var.create ? local.rules : {}
  security_group_id = local.this_sg_id
  direction         = lookup(each.value, "direction", null)

  port_range_min   = lookup(each.value, "port", lookup(each.value, "port_range_min", null))
  port_range_max   = lookup(each.value, "port", lookup(each.value, "port_range_max", null))
  protocol         = lookup(each.value, "protocol", null)
  ethertype        = lookup(each.value, "ethertype", null)
  description      = lookup(each.value, "description", null)
  remote_ip_prefix = (
  lookup(each.value, "remote_ip_prefix", null) == null
  ? (
  lookup(each.value, "ethertype", null) == "IPv6"
  ? (lookup(each.value, "remote_group_id", null) == null ? var.default_ipv6_remote_ip_prefix : null)
  : (lookup(each.value, "remote_group_id", null) == null ? var.default_ipv4_remote_ip_prefix : null)
  )
  : lookup(each.value, "remote_ip_prefix", null)
  )
  remote_group_id = (
  lookup(each.value, "remote_group_id", null) == "@self"
  ? local.this_sg_id
  : lookup(each.value, "remote_group_id", null)
  )
}

