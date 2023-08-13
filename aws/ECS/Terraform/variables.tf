#################### GLOBAL #####################

variable "region" {
  type    = string
  default = ""
}

#################### NETWORKING #####################

variable "networking" {
  # type    = any # TODO - Change this type later
  type = object({
    
    vpc = object({
      name=string
      cidr_block=string
      enable_dns_hostnames=bool
      enable_dns_support=bool
    })

    public-subnets = map(
      object({
        cidr_block              = string
        map_public_ip_on_launch = bool
      })
    )
    
    route-table-name = string 

    # If ommited, we'll not have an internet gateway
    internet-gateway-name = optional(string)
  })

}
