
#resource "aws_route53_record" "wildcard" {
#  count = var.create_public_nlb || var.create_private_nlb ? 1 : 0
#
#  zone_id = data.aws_route53_zone.this.id
#  name    = format("*.apps.%s", var.cluster_name)
#  type    = "CNAME"
#  ttl     = "300"
#  records = [
#    var.create_public_nlb ? module.nlb.lb_dns_name : module.nlb_private.lb_dns_name,
#  ]
#}
