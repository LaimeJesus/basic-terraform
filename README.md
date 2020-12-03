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

```
➜  basic-terraform git:(master) terraform init
2020/12/03 00:39:36 [WARN] Log levels other than TRACE are currently unreliable, and are supported only for backward compatibility.
  Use TF_LOG=TRACE to see Terraform's internal logs.
  ----
2020/12/03 00:39:36 [INFO] Terraform version: 0.13.1
2020/12/03 00:39:36 [INFO] Go runtime version: go1.14.7
2020/12/03 00:39:36 [INFO] CLI args: []string{"/home/shisus/opt/terraform/terraform", "init"}
2020/12/03 00:39:36 [INFO] CLI command args: []string{"init"}
2020/12/03 00:39:36 [WARN] Log levels other than TRACE are currently unreliable, and are supported only for backward compatibility.
  Use TF_LOG=TRACE to see Terraform's internal logs.
  ----

Initializing the backend...
2020/12/03 00:39:36 [INFO] Failed to read plugin lock file .terraform/plugins/linux_amd64/lock.json: open .terraform/plugins/linux_amd64/lock.json: no such file or directory

Initializing provider plugins...
2020/12/03 00:39:36 [WARN] Failed to scan provider cache directory .terraform/plugins: cannot search .terraform/plugins: lstat .terraform/plugins: no such file or directory
- Finding digitalocean/digitalocean versions matching "1.22.2"...
2020/12/03 00:39:37 [WARN] Log levels other than TRACE are currently unreliable, and are supported only for backward compatibility.
  Use TF_LOG=TRACE to see Terraform's internal logs.
  ----
2020/12/03 00:39:37 [WARN] Log levels other than TRACE are currently unreliable, and are supported only for backward compatibility.
  Use TF_LOG=TRACE to see Terraform's internal logs.
  ----
- Installing digitalocean/digitalocean v1.22.2...
- Installed digitalocean/digitalocean v1.22.2 (signed by a HashiCorp partner, key ID F82037E524B9C0E8)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/plugins/signing.html

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Luego de ejecutar este comando, deberíamos tener creada la carpeta `.terraform/plugins` con el plugin de DigitalOcean en la versión especificada.

#### Armado de Plan

Terraform funciona generando planes de ejecución con la infraestructura a crear. De esta manera, se pueden visualizar los objetos a crear en el proveedor definido.

Podemos revisar el resultado de nuestra configuración con el siguiente comando:

- `$ terraform plan`

Que genera el siguiente output

```shell
➜  basic-terraform git:(master) ✗ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.digitalocean_ssh_key.do_ssh_key: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_domain.default will be created
  + resource "digitalocean_domain" "default" {
      + id         = (known after apply)
      + ip_address = (known after apply)
      + name       = "**************"
      + urn        = (known after apply)
    }

  # digitalocean_droplet.www will be created
  + resource "digitalocean_droplet" "www" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "www"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = true
      + region               = "nyc1"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "29068776",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_loadbalancer.www-lb will be created
  + resource "digitalocean_loadbalancer" "www-lb" {
      + algorithm                = "round_robin"
      + droplet_ids              = (known after apply)
      + enable_backend_keepalive = false
      + enable_proxy_protocol    = false
      + id                       = (known after apply)
      + ip                       = (known after apply)
      + name                     = "www-lb"
      + redirect_http_to_https   = false
      + region                   = "nyc1"
      + status                   = (known after apply)
      + urn                      = (known after apply)
      + vpc_uuid                 = (known after apply)

      + forwarding_rule {
          + entry_port      = 80
          + entry_protocol  = "http"
          + target_port     = 80
          + target_protocol = "http"
          + tls_passthrough = false
        }

      + healthcheck {
          + check_interval_seconds   = 10
          + healthy_threshold        = 5
          + port                     = 22
          + protocol                 = "tcp"
          + response_timeout_seconds = 5
          + unhealthy_threshold      = 3
        }

      + sticky_sessions {
          + cookie_name        = (known after apply)
          + cookie_ttl_seconds = (known after apply)
          + type               = (known after apply)
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

Finalmente, aplicaremos nuestra configuración

- `$ terraform apply`

Generando un output bastante extenso por lo que nos concentraremos en las partes interesantes:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

digitalocean_droplet.www: Creating...
digitalocean_droplet.www: Still creating... [10s elapsed]
digitalocean_droplet.www: Still creating... [20s elapsed]
digitalocean_droplet.www: Provisioning with 'remote-exec'...
digitalocean_droplet.www: Still creating... [50s elapsed]
digitalocean_droplet.www (remote-exec): Connecting to remote host via SSH...
digitalocean_droplet.www (remote-exec):   Host: 157.230.91.145
digitalocean_droplet.www (remote-exec):   User: root
digitalocean_droplet.www (remote-exec):   Password: false
digitalocean_droplet.www (remote-exec):   Private key: true
digitalocean_droplet.www (remote-exec):   Certificate: false
digitalocean_droplet.www (remote-exec):   SSH Agent: true
digitalocean_droplet.www (remote-exec):   Checking Host Key: false
digitalocean_droplet.www (remote-exec): Connected!
digitalocean_droplet.www (remote-exec): 0% [Working]
digitalocean_droplet.www (remote-exec): Get:1 http://security.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
digitalocean_droplet.www (remote-exec): 0% [Waiting for headers] [1 InRelease 1
....
digitalocean_droplet.www: Creation complete after 2m35s [id=219696560]
digitalocean_loadbalancer.www-lb: Creating...
....
digitalocean_loadbalancer.www-lb: Still creating... [1m40s elapsed]
digitalocean_loadbalancer.www-lb: Creation complete after 1m45s [id=95019cdd-582f-48c8-abf5-ce0d5f65c3ac]
digitalocean_domain.default: Creating...
digitalocean_domain.default: Creation complete after 2s [id=**********]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Luego de unos minutos, podemos ver los recursos creados.

![terraform-recursos-do](https://i.ibb.co/F03hn23/3-terraform-do.png)

Terraform mantiene el estado y configuraciones de la infraestructura deployada en un archivo llamado `terraform.tfstate`. Este archivo contiene la información de cada recurso y variables realizadas en el último despliegue. Además, el estado de este archivo se puede actualizar cuando se realizan cambios por fuera del mismo Terraform, por ejemplo, borrando droplets desde la interfáz gráfica de DigitalOcean.

Podemos ver el estado actual de la infraestructura con el siguiente comando:

- `$ terraform show terraform.tfstate`

### Destrucción de la Infraestructura

Es posible destruir todos los objetos DigitalOcean creados en esta Infraestructura. Para esto terraform nos permite cambiar el plan a uno de destrucción mediante el argumento `-destroy`(también vamos a agregar -out para cargar este plan de destrucción en la variable tfplan de terraform):
- `$ terraform plan -destroy -out=terraform.tfplan`

El resultado de este comando es una secuencia de comandos muy extensa por lo que dejamos los más interesantes:

```
➜  basic-terraform git:(master) ✗ terraform plan -destroy -out=terraform.tfplan
....
data.digitalocean_ssh_key.do_ssh_key: Refreshing state... [id=29068776]
digitalocean_droplet.www: Refreshing state... [id=219696560]
digitalocean_loadbalancer.www-lb: Refreshing state... [id=95019cdd-582f-48c8-abf5-ce0d5f65c3ac]
digitalocean_domain.default: Refreshing state... [id=******]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # digitalocean_domain.default will be destroyed
  - resource "digitalocean_domain" "default" {
.......
  # digitalocean_droplet.www will be destroyed
  - resource "digitalocean_droplet" "www" {
.......
  # digitalocean_loadbalancer.www-lb will be destroyed
  - resource "digitalocean_loadbalancer" "www-lb" {
.......
Plan: 0 to add, 0 to change, 3 to destroy.

------------------------------------------------------------------------

This plan was saved to: terraform.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "terraform.tfplan"
```

Podemos ver que serán destruidos los 3 recursos creados, aplicando el plan guardado en la variable `terraform.tfplan`.
Finalmente, aplicamos el plan de destrucción:

- `$ terraform apply terraform.tfplan`

Con el siguiente resultado

```
➜  basic-terraform git:(master) ✗ terraform apply terraform.tfplan
digitalocean_domain.default: Destroying... [id=********]
digitalocean_domain.default: Destruction complete after 2s
digitalocean_loadbalancer.www-lb: Destroying... [id=95019cdd-582f-48c8-abf5-ce0d5f65c3ac]
digitalocean_loadbalancer.www-lb: Destruction complete after 1s
digitalocean_droplet.www: Destroying... [id=219696560]
digitalocean_droplet.www: Still destroying... [id=219696560, 10s elapsed]
digitalocean_droplet.www: Still destroying... [id=219696560, 20s elapsed]
digitalocean_droplet.www: Destruction complete after 24s

Apply complete! Resources: 0 added, 0 changed, 3 destroyed.
```

Fin de la guia

## Referencias

- https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean
- https://www.digitalocean.com/community/tutorials/how-to-structure-a-terraform-project
- https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/
- https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-2
- https://stackoverflow.com/questions/59789730/how-can-i-read-environment-variables-from-a-env-file-into-a-terraform-script
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/domain
