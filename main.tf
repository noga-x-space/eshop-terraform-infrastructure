terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.8.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Client configuration to retrieve tenant and object ID
data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "noga-rg" {
  name     = "rg-noga"
  location = "West Europe"
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
}

# IF YOU ALSO WANT THE SECRETS TO BE STORED ON AZ - USE THIS :

## secrets ##
# Azure Key Vault setup
resource "azurerm_key_vault" "key_vault" {
  name                        = "key-vault-terraform"
  location                    = azurerm_resource_group.noga-rg.location
  resource_group_name         = azurerm_resource_group.noga-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# Access policy for Key Vault
resource "azurerm_key_vault_access_policy" "access_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "Set", "List", "Delete", "Purge"
  ]

  depends_on = [azurerm_key_vault.key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_PASSWORD" {
  name         = "postgres-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_key_vault_access_policy.access_policy]
}
resource "azurerm_key_vault_secret" "VM_WEB_PASSWORD" {
  name         = "postgres-password"
  value        = var.az_web_admin_password
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_key_vault_access_policy.access_policy]
}
resource "azurerm_key_vault_secret" "VM_BACKEND_PASSWORD" {
  name         = "postgres-password"
  value        = var.az_back_admin_password
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_key_vault_access_policy.access_policy]
}
resource "azurerm_key_vault_secret" "VM_DB_PASSWORD" {
  name         = "postgres-password"
  value        = var.az_db_admin_password  # Ensure var.db_password is set in your variables file
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_key_vault_access_policy.access_policy]
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "terraform-vnet" {
  name                = "vnet-terraform"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
}

resource "azurerm_subnet" "subnet-front" {
  name                 = "subnet-front"
  resource_group_name  = azurerm_resource_group.noga-rg.name
  virtual_network_name = azurerm_virtual_network.terraform-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "subnet-back" {
  name                 = "subnet-back"
  resource_group_name  = azurerm_resource_group.noga-rg.name
  virtual_network_name = azurerm_virtual_network.terraform-vnet.name
  address_prefixes     = ["10.0.2.0/24"]

}


resource "azurerm_network_security_group" "nsg-front" {
  name                = "nsg-front"
  location            = azurerm_resource_group.noga-rg.location
  resource_group_name = azurerm_resource_group.noga-rg.name
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }

  //allows all ports to get to the frontend
  security_rule {
    name                       = "allow-http-front"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet-front.address_prefixes[0]
  }

  security_rule {
    name                       = "allow-http-back"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet-front.address_prefixes[0]
  }
  //allows ssh connection to the frontend vm for checks
  security_rule {
    name                       = "allow-ssh"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.my_ip.response_body)}/32"
    destination_address_prefix = azurerm_subnet.subnet-front.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association-front" {
  subnet_id                 = azurerm_subnet.subnet-front.id
  network_security_group_id = azurerm_network_security_group.nsg-front.id
}


resource "azurerm_network_security_group" "nsg-back" {
  name                = "nsg-back"
  location            = azurerm_resource_group.noga-rg.location
  resource_group_name = azurerm_resource_group.noga-rg.name
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }

  security_rule {
    name                       = "allow-front-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8000"
    destination_port_range     = "5432"
    source_address_prefix      = azurerm_subnet.subnet-front.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.subnet-back.address_prefixes[0]
  }
  security_rule {
    name                       = "allow-ssh-access"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.my_ip.response_body)}/32"
    destination_address_prefix = azurerm_subnet.subnet-back.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association-back" {
  subnet_id                 = azurerm_subnet.subnet-back.id
  network_security_group_id = azurerm_network_security_group.nsg-back.id
}


resource "azurerm_public_ip" "public_ip_web" {
  name                = "ip_public_web"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  allocation_method   = "Static"

  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
}

resource "azurerm_public_ip" "public_ip_db" {
  name                = "ip_public_db"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  allocation_method   = "Static"

  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
}

resource "azurerm_network_interface" "nic_web" {
  name                = "web-nic"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet-front.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_web.id
  }
}


resource "azurerm_network_interface_security_group_association" "web_nic_nsg_associate" {
  network_interface_id      = azurerm_network_interface.nic_web.id
  network_security_group_id = azurerm_network_security_group.nsg-front.id
}


/// back- db
resource "azurerm_network_interface" "nic_db" {
  name                = "db-nic"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet-back.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_db.id
  }
}

resource "azurerm_network_interface_security_group_association" "db_nic_nsg_associate" {
  network_interface_id      = azurerm_network_interface.nic_db.id
  network_security_group_id = azurerm_network_security_group.nsg-back.id
}




///////////////////////// creating the resources

resource "azurerm_linux_virtual_machine" "frontend" {
  name                = "vm-front"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  size                = "Standard_DS1_v2"

  admin_username = "adminuser"
  admin_password = var.az_web_admin_password
  network_interface_ids = [
    azurerm_network_interface.nic_web.id,
  ]
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  depends_on = [azurerm_virtual_machine_extension.vm-extension-db]

}



resource "azurerm_virtual_machine_extension" "vm-extension-web" {
  name                 = "vm-extension-web-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.frontend.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
  settings = jsonencode({
    commandToExecute = <<-EOF
     #!/bin/bash
     # Set noninteractive mode
     export DEBIAN_FRONTEND=noninteractive
  
     # Update package index without interaction
     sudo apt-get update -y > /dev/null 2>&1
  
     # Install packages without interaction
     sudo apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1
  
     # Set up Docker repository without TTY
     sudo mkdir -p /etc/apt/keyrings
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
     
     # Add repository without interaction
     echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
       sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
     # Update again silently
     sudo apt-get update -y > /dev/null 2>&1
  
     # Install Docker without interaction
     sudo apt-get install -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
  
     # Start and enable Docker
     sudo systemctl start docker
     sudo systemctl enable docker
  
     # Check existing container and its status
     if sudo docker ps -a | grep backend; then
         echo "Found existing backend container, checking status..."
         
         # Get container status
         STATUS=$(sudo docker inspect -f '{{.State.Status}}' backend 2>/dev/null || echo "not_found")
         echo "Container status: $STATUS"
         
         # Remove container regardless of status
         sudo docker stop backend || true
         sudo docker rm backend || true
         echo "Removed existing container"
     fi

     if sudo docker ps -a | grep frontend; then
         echo "Found existing frontend container, checking status..."
         
         # Get container status
         STATUS=$(sudo docker inspect -f '{{.State.Status}}' frontend 2>/dev/null || echo "not_found")
         echo "Container status: $STATUS"
         
         # Remove container regardless of status
         sudo docker stop frontend || true
         sudo docker rm frontend || true
         echo "Removed existing container"
     fi
     
     # Check if network exists and create if not
     if ! docker network inspect web-network >/dev/null 2>&1; then
         echo "Creating web-network network..."
         docker network create web-network
     fi

     # Run the application with health check
     sudo docker run -d --network=web-network -p 8000:8000 \
        --restart=always \
        -e DB_USER=${var.username} \
        -e PASSWORD=${var.db_password} \
        -e HOST='${azurerm_network_interface.nic_db.private_ip_address}' \
        -e DBPORT=5432 \
        -e DB_NAME=${var.db_name} \
        --name backend nogadocker/backend:latest
     sudo docker ps -q -f name=backend || { echo "Waiting for backend to start..."; sleep 10; }
     sudo docker run -d \
        --network=web-network \
        -e REACT_APP_BACKEND_URL='http://${azurerm_public_ip.public_ip_web.ip_address}' \
        -p 3000:3000 --name frontend nogadocker/frontend:latest
    EOF
  })
}

data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "azurerm_linux_virtual_machine" "db" {
  name                = "vm-db"
  resource_group_name = azurerm_resource_group.noga-rg.name
  location            = azurerm_resource_group.noga-rg.location
  size                = "Standard_DS1_v2"

  admin_username = "adminuser"
  admin_password = var.az_db_admin_password
  network_interface_ids = [
    azurerm_network_interface.nic_db.id,
  ]
  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}


resource "azurerm_virtual_machine_extension" "vm-extension-db" {
  name                 = "vm-extension-db-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.db.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  tags = {
    (var.tag-name) = "${var.tag-value}"
  }
  settings = jsonencode({
    commandToExecute = <<-EOF
     #!/bin/bash  
     # Set noninteractive mode
     export DEBIAN_FRONTEND=noninteractive
  
     # Update package index without interaction
     sudo apt-get update -y > /dev/null 2>&1
  
     # Install packages without interaction
     sudo apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1
  
     # Set up Docker repository without TTY
     sudo mkdir -p /etc/apt/keyrings
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
     
     # Add repository without interaction
     echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
       sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
     # Update again silently
     sudo apt-get update -y > /dev/null 2>&1
  
     # Install Docker without interaction
     sudo apt-get install -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
  
     # Start and enable Docker
     sudo systemctl start docker
     sudo systemctl enable docker


     if sudo docker ps -a | grep postgres; then
         echo "Found existing postgres container, checking status..."
         
         # Get container status
         STATUS=$(sudo docker inspect -f '{{.State.Status}}' postgres 2>/dev/null || echo "not_found")
         echo "Container status: $STATUS"
         
         # Remove container regardless of status
         sudo docker stop postgres || true
         sudo docker rm postgres || true
         echo "Removed existing container"
     fi

     sudo apt update && apt install wget postgresql-client -y
     sudo docker pull postgres:latest
     sudo docker run -d --name postgres \
       --restart=always \
       -e POSTGRES_USER=${var.username} \
       -e POSTGRES_PASSWORD=${var.db_password} \
       -e POSTGRES_DB=${var.db_name} \
       -p 5432:5432 \
       -v postgres_data:/var/lib/postgresql/data \
       postgres:latest

     # Wait for PostgreSQL to be ready
     sleep 15

     wget https://raw.githubusercontent.com/noga-x-space//eshop-terraform-infrastructure/main/script.sql
     export PGPASSWORD=${var.db_password}     
     psql -U ${var.username} -h localhost -f script.sql
    EOF
  })
}


