ENV                         = "dev"
PREFIX                      = "IT"

vnet                        = ["10.0.0.0/16"]

web                         = "websubnets"
subnet_address              = ["10.0.1.0/24"]

app                         = "appsubnet"
app_address                 = ["10.0.11.0/24"]

db                          = "dbsubnet"
db_address                  = ["10.0.21.0/24"]

bastion                     = "bastionsubnet"
bastion_address             = ["10.0.100.0/24"]


