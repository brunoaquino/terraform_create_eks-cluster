# Arquitetura de Referência EKS

Este projeto implementa uma arquitetura segura para Amazon EKS com foco em boas práticas de segurança de rede, auto scaling e integração com serviços AWS.

## Arquitetura de Rede

A arquitetura de rede segue o princípio de defesa em profundidade, com múltiplas camadas de segurança:

```
# Para visualizar o diagrama completo, gere a imagem a partir do arquivo rede-eks-topology-simple.puml
# Comando: plantuml rede-eks-topology-simple.puml
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

## Stack de Monitoramento e Observabilidade

O projeto inclui uma stack completa de monitoramento e observabilidade:

1. **Prometheus**

   - Coleta de métricas do cluster e aplicações
   - Armazenamento persistente: 8Gi
   - Configurado com recursos adequados para produção

2. **Grafana**

   - Interface de visualização para métricas e logs
   - Armazenamento persistente: 5Gi
   - Dashboards pré-configurados:
     - Istio Mesh, Service e Workload
     - Logs do Loki
     - Visão geral de pods Kubernetes

3. **Loki**

   - Sistema centralizado de logs
   - Armazenamento persistente: 10Gi
   - Integrado com Grafana como fonte de dados

4. **Promtail**

   - Agente para coleta de logs de todos os nós
   - Configurado com tolerâncias para rodar em todos os nós

5. **Jaeger**

   - Rastreamento distribuído
   - Integrado com Istio para telemetria

6. **Kiali**
   - Gerenciamento e visualização do service mesh
   - Integrado com Prometheus e Jaeger

## Service Mesh com Istio

O projeto implementa o Istio como service mesh com:

1. **Componentes**

   - Control Plane (istiod)
   - Ingress Gateway
   - Egress Gateway (opcional)
   - Ferramentas de monitoramento

2. **Segurança**

   - TLS automático com certificados wildcard
   - Política de tráfego através de gateways e virtual services

3. **Observabilidade**
   - Métricas de serviço
   - Visualização de topologia
   - Rastreamento de requisições

## Estrutura do Projeto

```
terraform_create_eks-cluster/
│
├── main.tf                  # Configuração principal do Terraform
├── variables.tf             # Definição de variáveis
├── terraform.tfvars         # Valores das variáveis
├── outputs.tf               # Outputs do Terraform
├── helm-charts.tf           # Configuração de todos os Helm charts
│
├── modules/                 # Módulos reutilizáveis
│   ├── master/              # Módulo para plano de controle do EKS
│   └── node/                # Módulo para nós do EKS
│
├── rede-eks-topology-simple.puml  # Diagrama da arquitetura de rede
└── README.md                # Esta documentação
```

## URLs de Acesso

Após a implantação, os seguintes serviços estarão disponíveis nos endpoints abaixo (substitua `mixnarede.com.br` pelo valor configurado em `base_domain`):

### Monitoramento e Observabilidade

| Serviço | URL                                | Descrição                    |
| ------- | ---------------------------------- | ---------------------------- |
| Grafana | `https://grafana.mixnarede.com.br` | Dashboard de métricas e logs |
| Kiali   | `https://kiali.mixnarede.com.br`   | Dashboard do Service Mesh    |
| Jaeger  | `https://jaeger.mixnarede.com.br`  | Interface de rastreamento    |

### Acesso a APIs e Aplicações

Os serviços implantados no cluster estarão disponíveis através do Istio Ingress Gateway, seguindo o padrão:

```
https://<nome-do-servico>.mixnarede.com.br
```

Para expor um novo serviço, crie um Virtual Service conforme o exemplo:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: meu-servico
  namespace: meu-namespace
spec:
  hosts:
    - "meu-servico.mixnarede.com.br"
  gateways:
    - istio-ingress/default-gateway
  http:
    - route:
        - destination:
            host: meu-servico.meu-namespace.svc.cluster.local
            port:
              number: 80
```

## Configuração do Armazenamento

O projeto utiliza volumes persistentes para vários componentes:

| Componente | Tamanho Padrão | Variável de Configuração             |
| ---------- | -------------- | ------------------------------------ |
| Prometheus | 8Gi            | `monitoring.prometheus_storage_size` |
| Grafana    | 5Gi            | `monitoring.grafana_storage_size`    |
| Loki       | 10Gi           | `monitoring.loki_storage_size`       |

Os volumes são provisionados automaticamente no AWS EBS através do provisionador padrão do EKS.

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

### Acesso aos Serviços

Após a implantação, os URLs mencionados acima estarão disponíveis depois que:

1. O DNS se propagar (gerenciado pelo external-dns)
2. Os certificados forem validados e emitidos (gerenciado pelo cert-manager)

Isto pode levar alguns minutos após a conclusão do Terraform.

### Verificação da Implantação

```bash
# Verificar namespaces
kubectl get namespaces

# Verificar pods do Istio
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress
kubectl get pods -n istio-monitoring

# Verificar certificados
kubectl get certificates -n istio-ingress
kubectl get certificaterequests -n istio-ingress

# Verificar gateways e virtual services
kubectl get gateway -A
kubectl get virtualservice -A
```

## Estimativa de Custos

A tabela abaixo fornece uma estimativa mensal aproximada dos custos da infraestrutura AWS para este projeto. Os valores são baseados na configuração padrão em `terraform.tfvars` e consideram o uso apenas em dias úteis (segunda a sexta-feira) das 8h às 18h.

| Recurso             | Detalhes                               | Custo Mensal c/ Uso Contínuo | Custo Mensal c/ Horário Comercial |
| ------------------- | -------------------------------------- | ---------------------------- | --------------------------------- |
| EKS Cluster         | Plano de controle                      | $73                          | $24.30                            |
| Nós EC2 (t3.large)  | 2 nós, 2 vCPU, 8GB RAM cada            | $140                         | $46.70                            |
| NAT Gateway         | 1 gateway para ambiente dev            | $32                          | $10.70                            |
| Load Balancer (NLB) | Para Istio Ingress Gateway             | $16                          | $5.30                             |
| EBS Volumes         | 23GB total (Prometheus, Grafana, Loki) | $2.30                        | $2.30 (cobrado mesmo desligado)   |
| Route 53            | Zona hospedada + consultas             | $0.50                        | $0.50                             |
| S3                  | Armazenamento mínimo                   | $0.50                        | $0.50                             |
| CloudWatch          | Logs e métricas                        | $10                          | $3.30                             |
| Data Transfer       | Estimativa conservadora                | $20                          | $6.70                             |
| **Total estimado**  |                                        | **~$295/mês**                | **~$100/mês**                     |

> **Nota sobre cálculo:** O uso em horário comercial (8h-18h, segunda a sexta) representa aproximadamente 50 horas por semana, ou cerca de 33% do tempo total. Os custos foram ajustados proporcionalmente, exceto para armazenamento que é cobrado independentemente do uso.

### Notas sobre custos

1. **Otimizações para ambiente dev:**

   - A configuração usa `single_az_mode = true` para reduzir custos
   - Tipos de instância t3.large são adequados para desenvolvimento
   - Apenas 2 nós são utilizados no ambiente dev
   - **Uso apenas em horário comercial** (8h-18h, dias úteis) reduz significativamente os custos

2. **Implementação da programação de horário:**

   - Recomendamos usar o AWS Instance Scheduler ou uma solução baseada em Lambda/EventBridge para:
     - Iniciar o cluster automaticamente às 8h nos dias úteis
     - Desligar o cluster às 18h nos dias úteis
     - Manter o cluster desligado nos fins de semana
   - Script exemplo para automação: [terraform-aws-instance-scheduler](https://github.com/terraform-aws-modules/terraform-aws-instance-scheduler)

3. **Opções para redução adicional de custos:**

   - Use instâncias spot para os nós de worker (economia adicional de até 70%)
   - Reduza o tamanho dos volumes de armazenamento persistente
   - Use Fargate em vez de nós EC2 para cargas de trabalho menores

4. **Estimativa para produção:**
   - Para ambiente de produção (multi-AZ, mais nós, instâncias maiores, 24/7), o custo pode aumentar para $600-900/mês

> **Importante:** Estas são estimativas aproximadas. Recomendamos usar a [Calculadora de Preços AWS](https://calculator.aws/) para estimativas mais precisas baseadas em sua carga de trabalho específica e região.

## Boas Práticas Implementadas

1. Arquitetura multi-AZ para alta disponibilidade
2. Princípio de privilégio mínimo para IAM
3. Segurança em camadas (defesa em profundidade)
4. Isolamento de rede para bancos de dados
5. VPC Endpoints para comunicação segura com serviços AWS
6. Auto scaling baseado em múltiplas métricas
7. Suporte para modo de zona única para ambientes de desenvolvimento
8. Stack completa de observabilidade com métricas, logs e tracing
9. Service mesh para segurança e controle de tráfego
10. Automação de DNS e certificados TLS
