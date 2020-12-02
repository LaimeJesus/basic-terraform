# Guia sobre Terraform

Esta guia contiene ejemplos de uso de la herramienta Terraform implementando instancias de máquinas virtuales creadas en Digital Ocean.

## Requerimientos

- DigitalOcean Account
- Personal Access Token
- SSH Public Key

### Primer Paso

Generar la clave de acceso Personal de la cuenta de Digital Ocean a utilizar.

### Segundo Paso

Generar un par de claves SSH nuevas en la máquina donde utilizaremos terraform. Y luego las agregaremos a nuestra cuenta de Digital Ocean.

En nuestro caso la llamamos: digitalocean

## Introducción

Terraform is a command-line tool that you run on your desktop or on a remote server. To install it, you’ll download it and place it on your PATH so you can execute it in any directory you’re working in.

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

Configuration files describe to Terraform the components needed to run a single application or your entire datacenter. Terraform generates an execution plan describing what it will do to reach the desired state, and then executes it to build the described infrastructure. As the configuration changes, Terraform is able to determine what changed and create incremental execution plans which can be applied.

The infrastructure Terraform can manage includes low-level components such as compute instances, storage, and networking, as well as high-level components such as DNS entries, SaaS features, etc.

## Comandos


Instalar Terraform
- `$ curl -o ~/terraform.zip https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip`
- `$ mkdir -p ~/opt/terraform`
- `$ unzip ~/terraform.zip -d ~/opt/terraform`
- `$ vim ~/.zshrc`
    - export PATH=$PATH:~/opt/terraform/

Opcional: Definir las variables de ambiente a usar en un archivo .env, sino configurarlas en la session
- `$ touch .env`
agregar la variable TF_VAR_DO_PAT, con la clave de acceso
y la agregamos a las variables actuales
- `$ source .env`

Crear Configuración de un Provisioner

- `$ touch provider.tf`

Luego de agregar la configuración, iniciamos nuestra instancia de TF

- `$ terraform init`

Crear la Configuración del servidor/droplet a instanciar en DigitalOcean

- `$ touch www-1.tf`

Una vez listo, vamos a revisar cuál sería el resultado de aplicar nuestra nueva configuración

- `$ terraform plan`

Finalmente, aplicaremos nuestra configuración

- `$ terraform apply`

Luego de unos minutos, podemos ver el droplet creado. También podemos ver el estado actual de Terraform con el siguiente comando:

- `$ terraform show terraform.tfstate`

### Replicacion de Máquinas

Probemos generar una nueva máquina virtual con una configuración idéntica a la anterior

- `$ sed 's/www-1/www-2/g' www-1.tf > www-2.tf`

Ahora, volvemos a ver el plan de esta configuración. Debería aparecer un nuevo droplet a crear

- `$ terraform plan`

Finalmente aplicamos este plan

- `$ terraform apply`

### Creación de un Load Balancer

- `$ touch loadbalancer.tf`

Luego de configurarlo, vamos a aplicarlo

- `$ terraform plan`
- `$ terraform apply`

### Creación de Registro DNS

Recordar tener configurado el dominio a utilizar

- `$ touch domain.tf`

Luego de configurarlo, vamos a aplicarlo

- `$ terraform plan`
- `$ terraform apply`

### Destrucción de la Infraestructura

Vamos a destruir los objetos de Digital Ocean creados, para esto terraform nos permite cambiar el plan a uno de destrucción mediante el argumento -destroy(también vamos a agregar -out para cargar este plan de destrucción en la variable tfplan de terraform)
- `$ terraform plan -destroy -out=terraform.tfplan`

Finalmente, aplicamos este plan de destrucción

- `$ terraform apply terraform.tfplan`

## Referencias

- https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean
- https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/
- https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-2
- https://stackoverflow.com/questions/59789730/how-can-i-read-environment-variables-from-a-env-file-into-a-terraform-script
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/domain

=================

Problemas resueltos

se estaba agregando una carpeta /bin inexistente

cambiar
- export PATH=$PATH:~/opt/terraform/bin/
por
- export PATH=$PATH:~/opt/terraform/

no es posible crear un droplet en la region nyc2

cambiar
region = "nyc2"
por
region = "nyc1"

Mismo problema anterior, pero en el caso del loadbalancer

cambiar
  region = "nyc2"
por
  region = "nyc1"
