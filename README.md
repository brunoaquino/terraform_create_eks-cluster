# Arquitetura de Referência EKS

Este projeto implementa uma arquitetura segura para Amazon EKS com foco em boas práticas de segurança de rede, auto scaling e integração com serviços AWS.

## Arquitetura de Rede

A arquitetura de rede segue o princípio de defesa em profundidade, com múltiplas camadas de segurança:

```
# Para visualizar o diagrama completo, gere a imagem a partir do arquivo rede-eks-topology.puml
# Comando: plantuml rede-eks-topology.puml
```

### Componentes Principais

1. **VPC Segmentada**

   - CIDR principal: `10.0.0.0/16`
   - Subnets privadas para nós do EKS: `10.0.1.0/24`, `10.0.2.0/24`
   - Subnets públicas para load balancers: `10.0.101.0/24`, `10.0.102.0/24`
   - Subnets isoladas para bancos de dados: `10.0.201.0/24`, `10.0.202.0/24`

2. **Controles de Tráfego em Múltiplas Camadas**

   - Security Groups específicos por recurso
   - Network ACLs por tipo de subnet
   - Tabelas de rotas específicas para cada tipo de subnet
   - VPC Flow Logs para auditoria de tráfego

3. **Acesso à Internet Controlado**

   - Internet Gateway para subnets públicas
   - NAT Gateway para acesso à internet a partir de subnets privadas
   - Subnets de banco de dados totalmente isoladas da internet

4. **VPC Endpoints**
   - Acesso a serviços AWS sem passar pela internet pública
   - Endpoints configurados: ECR API, ECR Docker, S3, CloudWatch Logs, STS

## Segurança do Kubernetes

1. **IAM & RBAC**

   - Configuração OIDC para suporte a IAM Roles for Service Accounts
   - Papéis IAM específicos para cert-manager e external-dns
   - Pods operam com o princípio de privilégio mínimo

2. **Segurança de Rede**

   - Nós do EKS em subnets privadas
   - Acesso limitado à API do Kubernetes (Recomendado: restrinja para IPs corporativos)
   - Security groups configurados com regras restritivas

3. **Criptografia**
   - Suporte para cert-manager com Let's Encrypt
   - Armazenamento EBS criptografado via CSI driver

## Auto Scaling

O cluster possui configurações avançadas de auto scaling:

1. **Auto Scaling Baseado em CPU**

   - Escalonamento para cima: quando o uso de CPU atinge 80%
   - Escalonamento para baixo: quando o uso de CPU cai para 40%
   - Períodos de cooldown configurados para evitar oscilações

2. **Auto Scaling Baseado em Memória**
   - Escalonamento para cima: quando o uso de memória atinge 80%
   - Escalonamento para baixo: quando o uso de memória cai para 40%

## Integrações

1. **Route53 & DNS**

   - External-DNS para criação automática de registros DNS
   - Validação DNS para Let's Encrypt

2. **Istio & Service Mesh**
   - Configuração para suportar Istio como Service Mesh
   - Integração com cert-manager para TLS em gateways Istio

## Uso

### Inicialização

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Configuração do kubectl

```bash
aws eks update-kubeconfig --name app-cluster --region us-east-1
```

### Instalação de Componentes Adicionais

Consulte a documentação em `/docs` para instruções detalhadas sobre como instalar e configurar:

- Istio
- Cert-Manager
- External-DNS
- Prometheus/Grafana

## Boas Práticas Implementadas

1. Arquitetura multi-AZ para alta disponibilidade
2. Princípio de privilégio mínimo para IAM
3. Segurança em camadas (defesa em profundidade)
4. Isolamento de rede para bancos de dados
5. VPC Endpoints para comunicação segura com serviços AWS
6. Auto scaling baseado em múltiplas métricas
7. Suporte para modo de zona única para ambientes de desenvolvimento
