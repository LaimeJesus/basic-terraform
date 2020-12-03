# Guia sobre Terraform

## Introducción

Terraform es una herramienta que permite instalar, modificar y eliminar infraestructura de manera automática mediante archivos de configuración, lo que a su vez facilita su versionado. Terraform puede utilizar los proveedores cloud más conocidos como así soluciones customizadas.

A grandes rasgos, Terraform define planes de despliegue de Infraestructura y también hace el seguimiento del estado actual de los mismos. Gracias a esto, es posible operar la infraestructura de una aplicación simple cómo la de un datacenter entero.

En esta guía veremos los pasos para implementar la creación de Droplets, un Load Balancer y un Registro DNS de Digital Ocean.

Terraform funciona mediante archivos de configuración utilizando el formato Hashicorp Configuration Language(HCL), define múltiples objetos para la creación de Infraestructura de los cuáles destacamos: **provider**, **variable**, **data**, **resource** y **terraform**.

- **terraform**: este objeto contiene la configuración principal del proyecto Terraform, es el lugar donde se definen los proveedores a utilizar. [Link](https://www.terraform.io/docs/configuration/terraform.html).
- **provider**: este objeto contiene la configuración del proveedor a utilizar. Terraform puede utilizar diferentes tipos de proveedores Cloud como soluciones particulares, estas instalaciones se realizan como plugins. Los proveedores suelen usar configuraciones diferentes por lo cuál se debe revisar la documentación de cada proveedor específico. [Link 1](https://www.terraform.io/docs/configuration/providers.html), [Link 2](https://www.terraform.io/docs/providers/index.html).
- **resource**: este objeto contiene la configuración de los objetos de la infraestructura a desplegar, por ejemplo: Droplets, Load Balancer y Dominios de DigitalOcean, como también Máquinas Virtuales de AWS. [Link](https://www.terraform.io/docs/configuration/resources.html)
- **data**: este objeto permite extraer y obtener datos desde diversas fuentes locales o de servicios externos para ser usados en los archivos de Configuración de Terraform. Cada proveedor Cloud pueden disponer de datos diferentes, por ejemplo: claves SSH de Digital Ocean. [Link](https://www.terraform.io/docs/configuration/data-sources.html).
- **variable**: este objeto permite la configuración de variables que pueden ser utilizadas en los archivos de Configuración. Además, es posible utilizar variables de ambiente definidas en la sesión actual con este objeto, la definición de estas variables debe comenzar con TF_VAR, por ejemplo: TF_VAR_DO_TOKEN=12345. [Link](https://www.terraform.io/docs/configuration/variables.html).

## Requerimientos

- Cuenta en DigitalOcean
- Configuración de una Clave de Acceso Personal
- Configuración de una Clave Pública SSH
- Dominio Público Configurado

### Clave de Acceso Personal

Generar la clave de acceso Personal de la cuenta de Digital Ocean a utilizar. [Link]()

### Claves SSH

Generar un par de claves SSH nuevas en la máquina donde utilizaremos terraform. Para luego agregarlas a nuestra cuenta de Digital Ocean. [Link]()

## Despligue de Infraestructura

Ahora, comenzamos con la instalación de la infraestructura con los siguientes objetos de DigitalOcean: un droplet(nginx), un loadbalancer y un mapeo de DNS.

#### Instalar Terraform

Primero, debemos instalar el script Terraform y configurarlo como ejecutable.

- `$ curl -o ~/terraform.zip https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip`
- `$ mkdir -p ~/opt/terraform`
- `$ unzip ~/terraform.zip -d ~/opt/terraform`
- `$ echo "export PATH=$PATH:~/opt/terraform/" >> ~/.zshrc`
- `$ source ~/.zshrc`

Modificar `.basrhc` en caso de no usar zsh.

#### Definir Variables de Ambiente

Para realizar el despliegue en DigitalOcean necesitamos disponer a Terraform las siguientes variables: 
- **TF_VAR_DO_PAT**: la clave de acceso personal(Personal Access Token).
- **TF_VAR_PVT_KEY_PATH**: la ruta donde se encuentra la clave privada validada en DigitalOcean.
- **TF_VAR_DO_SSH_KEY_NAME**: el nombre de la clave SSH creada.
- **TF_VAR_DOMAIN**: el dominio público a utilizar en DigitalOcean.

Para utilizar estas variables vamos a crear un archivo `.env`, y luego las cargamos en las variables de la consola actual.

- `$ touch .env`
- `$ echo "export TF_VAR_DO_PAT=****************" >> .env`
- `$ echo "export TF_VAR_PVT_KEY_PATH=~/.ssh/id_rsa >> .env`
- `$ echo "export TF_VAR_DO_SSH_KEY_NAME=digitalocean >> .env`
- `$ echo "export TF_VAR_DOMAIN=dominio.publico.com >> .env`
- `$ source .env`

##### Configuración Terraform

Comenzaremos la configuración de Terraform con la creación de un archivo `versions.tf`:

- `$ touch versions.tf`

con el siguiente contenido:

```terraform
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
    }
  }
}
```

En esta configuración definimos como requerido el provider digitalocean, y con su plugin en la versión 1.22.2. 

Podemos revisar esta configuración inicial con el siguiente comando:

- `$ terraform validate`

##### Configuración Variables

Las variables a utilizar serán las mismas que las definidas como variables de ambiente, para esto crearemos el archivo `variables.tf`.

- `$ touch variables.tf`

Con el siguiente contenido

```terraform
variable "DO_PAT" {
    description = "This Variable contains the Personal Access Token from a Digital Ocean Account"
}

variable "PVT_KEY_PATH" {
    description = "Local Path for a SSH Public Key validated in the Digital Ocean Account"
}

variable "DO_SSH_KEY_NAME" {
    description = "SSH Public Key Name created in the Digital Ocean Account"
}

variable "DOMAIN" {
    description = "This Variable contains the Default Public Domain of the Infraestructure"
}
```

Cada linea `variable "VAR_NAME"` define la variable para ser usada luego como `var.VAR_NAME`.

#### Configuración Provider

En nuestro caso, vamos a seguir la documentación del plugin de [DigitalOcean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs). Crearemos el archivo `provider.tf`

- `touch provider.tf`

y lo configuraremos siguiente su documentación:

```terraform
provider "digitalocean" {
  token = var.DO_PAT
}
```

Definimo usar el plugin digitalocean, y le seteamos el valor token necesario para usar la cuenta de DigitalOcean.

#### Configuración de Objetos de Digital Ocean

Para esta guia vamos a crear los siguientes objetos de DigitalOcean:

- **droplet**, con un servicio Nginx
- **loadbalancer**, como servicio por defecto del dominio publico
- **dns**, para que el dominio publico sea administrado por DigitalOcean

Empezaremos creando el archivo `resources.tf`

- `$ touch resources.tf`

Explicaremos el contenido por partes:

Por un lado la definición del droplet. Ver Referencias: [Droplet](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet), [Connection](https://www.terraform.io/docs/provisioners/connection.html) y [Provisioner](https://www.terraform.io/docs/provisioners/index.html)

```
resource "digitalocean_droplet" "www" {
    image = "ubuntu-18-04-x64"
    name = "www"
    region = "nyc1"
    size = "s-1vcpu-1gb"
    private_networking = true
    ssh_keys = [
      data.digitalocean_ssh_key.do_ssh_key.id
    ]

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.PVT_KEY_PATH)
        timeout = "2m"
    }
    provisioner "remote-exec" {
        inline = [
            "export PATH=$PATH:/usr/bin",
            # install nginx
            "sudo apt-get update",
            "sudo apt-get -y install nginx"
        ]
    }
}
```

En la linea 1:

- `resource "digitalocean_droplet" "www" {`, definimos el recurso droplet __www__ del plugin DigitalOcean

En las lineas 2 a 9: configuración droplet
Definimos el tipo de droplet con sus configuraciones básicas. El atributo `ssh_keys`, permite definir la clave ssh con la cual se puede conectar al droplet, en nuestro caso, usando la variable `do_ssh_key` definida y conseguida gracias al archivo `data-sources.tf`, que explicaremos más adelante.

En las lineas 11 a 17: bloque de `connection`

El bloque de configuración `connection` es necesario para la configuración del bloque `provisioner`. Esta configuración tiene la definición con la conexión SSH. Como se puede ver, accede a la variable PVT_KEY_PATH, definida en el archivo `variables.tf` buscando el contenido del mismo usando la función __file__.

En las lineas 19 a 25: bloque de `provisioner`

Este bloque define los comandos a ejecutar en el droplet una vez creado. Para esto utiliza el tipo de provisioner "remote-exec" el cual tiene el bloque con las instrucciones a correr.

Pasemos a la configuración del recurso `loadbalancer`. Ver Referencia: [LoadBalancer](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/loadbalancer)

```
resource "digitalocean_loadbalancer" "www-lb" {
  name = "www-lb"
  region = "nyc1"

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.www.id]
}
```

Esta configuración es directa, el campo a destacar es el `droplet_ids`, el cual accede a la variable definida `www` creada dentro del atributo `digitalocean_droplet`. Esto nos permite mapear este droplet dentro de los máquinas que redistribuye carga el loadbalancer.

Finalmente, la configuración del `domain`. Ver Referencias: [domain](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/domain).

```
resource "digitalocean_domain" "default" {
   name = var.DOMAIN
   ip_address = digitalocean_loadbalancer.www-lb.ip
}
```

En este caso, definimos un nuevo `domain` llamado `default` el cual usa la variable de ambiente DOMAIN, el dominio público configurado, como el nombre del objeto DNS a crear. Además apunta por defecto al loadbalancer, de manera que creará un registro **A** hacia la dirección IP del loadbalancer.

#### Configuración Data Sources

Por último, vamos a crear la configuración de un data source de Terraform para obtener los datos de la clave pública validada en la cuenta de DigitalOcean. Este dato será necesario para acceder al droplet www definido anteriormente.

Comenzamos creando el archivo `data-sources.tf`

- `$ touch data-sources.tf`

Con el siguiente contenido:
```
data "digitalocean_ssh_key" "do_ssh_key" {
  name = var.DO_SSH_KEY_NAME
}
```

Esta configuración define el objeto do_ssh_key usando la API ssh_key de los data sources de DigitalOcean. Al mismo tiempo, le definimos en el atributo name cuál es la clave ssh que debe buscar, en nuestro caso usando la variable de ambiente __DO_SSH_KEY_NAME__.
Ver Referencia: [ssh_key](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/ssh_key).


#### Inicio de Configuración de Terraform

Finalmente, luego de definir todos los archivos de Configuración de Infraestructura a utilizar, podemos iniciar el estado de este proyecto Terraform con el siguiente comando:

- `$ terraform init`

Una vez listo, vamos a revisar cuál sería el resultado de aplicar nuestra nueva configuración

- `$ terraform plan`

Finalmente, aplicaremos nuestra configuración

- `$ terraform apply`

Luego de unos minutos, podemos ver el droplet creado. También podemos ver el estado actual de Terraform con el siguiente comando:

- `$ terraform show terraform.tfstate`

### Destrucción de la Infraestructura

Es posible destruir todos los objetos DigitalOcean creados en esta Infraestructura. Para esto terraform nos permite cambiar el plan a uno de destrucción mediante el argumento `-destroy`(también vamos a agregar -out para cargar este plan de destrucción en la variable tfplan de terraform)
- `$ terraform plan -destroy -out=terraform.tfplan`

Finalmente, aplicamos este plan de destrucción

- `$ terraform apply terraform.tfplan`

Fin de la guia

## Referencias

- https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean
- https://www.digitalocean.com/community/tutorials/how-to-structure-a-terraform-project
- https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/
- https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-2
- https://stackoverflow.com/questions/59789730/how-can-i-read-environment-variables-from-a-env-file-into-a-terraform-script
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/domain
