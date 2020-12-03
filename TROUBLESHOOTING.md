
# Troubleshooting

Algunos problemas que aparecieron durante el armado de la guia:

## Error en el comando de instalación de Terraform:

Se esperaba una carpeta /bin inexistente

```
cambiar
- echo "export PATH=$PATH:~/opt/terraform/bin" >> ~/.zshrc`
por
- echo "export PATH=$PATH:~/opt/terraform/" >> ~/.zshrc`
```

## Error en la selección de región de Droplet y Loadbalancer

No fue posible crear el droplet y el loadbalancer en la region nyc2

```
cambiar
region = "nyc2"
por
region = "nyc1"
```
