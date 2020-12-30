{
    "schemaVersion": "1.2",
    "description": "Join instances to an AWS Directory Service domain.",
    "runtimeConfig": {
      "aws:domainJoin": {
        "properties": {
          "directoryId": "${ad_directory_id}",
          "directoryName": "${ad_domain_fqdn}",
          "dnsIpAddresses": [
              "${ad_dns_ip1}",
              "${ad_dns_ip2}"
          ]
        }
      }
    }
  }