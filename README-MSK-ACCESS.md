# Acesso ao MSK a partir do EKS

Este documento explica como configurar suas aplicações para acessar o MSK a partir do EKS usando IAM Role for Service Accounts (IRSA).

## Como funciona

O Terraform cria automaticamente:

1. Uma política IAM com as permissões necessárias para acessar o MSK
2. Uma função IAM (role) que pode ser assumida por serviços do cluster
3. Um Service Account Kubernetes configurado para usar a função IAM

## Como usar o Service Account em suas aplicações

Para usar o Service Account em seus deployments, adicione a seguinte configuração:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minha-aplicacao
spec:
  template:
    spec:
      serviceAccountName: msk-access-sa # Nome do service account criado pelo Terraform
      containers:
        - name: meu-container
          # ...
```

## Exemplo de configuração para cliente Kafka com IAM

### Java

```java
Properties props = new Properties();
props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "BOOTSTRAP_SERVERS");
props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
props.put("security.protocol", "SASL_SSL");
props.put("sasl.mechanism", "AWS_MSK_IAM");
props.put("sasl.jaas.config", "software.amazon.msk.auth.iam.IAMLoginModule required;");
props.put("sasl.client.callback.handler.class", "software.amazon.msk.auth.iam.IAMClientCallbackHandler");

// Produtor
KafkaProducer<String, String> producer = new KafkaProducer<>(props);

// Consumidor
props.put(ConsumerConfig.GROUP_ID_CONFIG, "meu-grupo");
props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
```

### Python

```python
from kafka import KafkaProducer, KafkaConsumer
import boto3

# Configuração do cliente Kafka com autenticação IAM
producer = KafkaProducer(
    bootstrap_servers='BOOTSTRAP_SERVERS',
    security_protocol='SASL_SSL',
    sasl_mechanism='AWS_MSK_IAM',
    sasl_oauth_token_provider=boto3.Session().get_credentials()
)

# Consumidor
consumer = KafkaConsumer(
    'meu-topico',
    bootstrap_servers='BOOTSTRAP_SERVERS',
    security_protocol='SASL_SSL',
    sasl_mechanism='AWS_MSK_IAM',
    sasl_oauth_token_provider=boto3.Session().get_credentials(),
    group_id='meu-grupo',
    auto_offset_reset='earliest'
)
```

## Testando a conexão

Você pode criar um pod de teste para verificar a conexão ao MSK:

```yaml
# msk-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: msk-test-pod
  namespace: default
spec:
  serviceAccountName: msk-access-sa
  containers:
    - name: aws-cli
      image: amazon/aws-cli:latest
      command:
        - "sleep"
        - "3600"
      env:
        - name: AWS_REGION
          value: "us-east-1" # Substitua pela sua região AWS
  restartPolicy: Never
```

Aplique o pod de teste:

```bash
kubectl apply -f msk-test-pod.yaml
```

Depois, você pode acessar o pod e testar a conexão ao MSK:

```bash
# Acesse o pod de teste
kubectl exec -it msk-test-pod -- /bin/bash

# Execute comandos do AWS CLI para verificar o acesso ao MSK
aws kafka list-clusters --region <sua-região>
aws kafka get-bootstrap-brokers --cluster-arn <arn-do-cluster-msk> --region <sua-região>
```

## Solução de problemas

### Verificar permissões IAM

```bash
# Verificar informações da função IAM
aws iam get-role --role-name <nome-do-cluster>-msk-access-role

# Verificar políticas anexadas à função
aws iam list-attached-role-policies --role-name <nome-do-cluster>-msk-access-role
```

### Verificar configuração do Service Account

```bash
kubectl describe serviceaccount msk-access-sa
```

### Verificar configuração OIDC

```bash
# Verificar o emissor OIDC do cluster
aws eks describe-cluster --name <nome-do-cluster> --query "cluster.identity.oidc.issuer" --output text
```
