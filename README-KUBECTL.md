# Guia de Configuração do kubectl para EKS

Este guia explica como configurar o kubectl para acessar seu cluster EKS e fornece dicas úteis para gerenciar recursos no Kubernetes.

## Pré-requisitos

Antes de começar, certifique-se de ter instalado:

1. **AWS CLI**: Para autenticar com a AWS e acessar o EKS.

   - [Instruções de instalação da AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. **kubectl**: A ferramenta de linha de comando para Kubernetes.

   - [Instruções de instalação do kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

3. **jq**: Processador de JSON na linha de comando (opcional, mas recomendado).
   - Mac: `brew install jq`
   - Linux: `apt-get install jq` ou `yum install jq`

## Configuração do kubectl usando AWS CLI

### 1. Configurar Credenciais da AWS

Primeiro, configure suas credenciais AWS:

```bash
aws configure
```

Você precisará fornecer:

- AWS Access Key ID
- AWS Secret Access Key
- Default region (ex: us-east-1)
- Default output format (recomendado: json)

Alternativamente, configure usando variáveis de ambiente:

```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Verificar suas credenciais

Confirme que suas credenciais estão funcionando:

```bash
aws sts get-caller-identity
```

Você deve ver um resultado semelhante a este:

```json
{
  "UserId": "AIDAXXXXXXXXXXXX",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/seu-usuario"
}
```

### 3. Listar clusters EKS disponíveis

Para ver todos os clusters EKS na região atual:

```bash
aws eks list-clusters
```

### 4. Atualizar o arquivo kubeconfig

O comando principal para configurar o kubectl para acessar um cluster EKS é:

```bash
aws eks update-kubeconfig --name <nome-do-cluster> --region <região-aws>
```

Exemplo:

```bash
aws eks update-kubeconfig --name meu-cluster-eks --region us-east-1
```

Parâmetros importantes:

- `--name`: Nome do seu cluster EKS
- `--region`: Região AWS onde o cluster está (ex: us-east-1)
- `--alias` (opcional): Define um alias para o contexto
- `--kubeconfig` (opcional): Caminho para um arquivo kubeconfig específico
- `--role-arn` (opcional): ARN do papel IAM para assumir antes de se comunicar com o cluster

### 5. Verificar a configuração

Após atualizar o arquivo kubeconfig, verifique se foi configurado corretamente:

```bash
# Ver todos os contextos configurados
kubectl config get-contexts

# Ver o contexto atual
kubectl config current-context

# Testar a conexão listando os nós
kubectl get nodes
```

### 6. Alternar entre clusters

Se você tem múltiplos clusters configurados:

```bash
# Listar contextos disponíveis
kubectl config get-contexts

# Mudar para um contexto específico
kubectl config use-context <nome-do-contexto>
```

### 7. Autenticação com IAM Roles

Para clusters que exigem assumir um papel IAM específico:

```bash
aws eks update-kubeconfig --name <nome-do-cluster> --region <região> --role-arn arn:aws:iam::<conta-aws>:role/<nome-do-papel>
```

### 8. Troubleshooting da autenticação

Se você encontrar erros de autenticação:

1. Verifique se o usuário/papel IAM tem permissões adequadas:

   - Para usuários que criam o cluster: permissões são concedidas automaticamente
   - Para outros usuários: o criador do cluster precisa adicionar o usuário ao ConfigMap `aws-auth`

2. Para verificar o ConfigMap:

   ```bash
   kubectl -n kube-system get configmap aws-auth -o yaml
   ```

3. Para adicionar um usuário ao ConfigMap (as permissões corretas são necessárias):
   ```bash
   eksctl create iamidentitymapping --cluster <nome-do-cluster> --arn arn:aws:iam::<conta-aws>:user/<nome-do-usuario> --group system:masters
   ```

## Configuração Automatizada

Incluímos um script para configurar automaticamente o kubectl para seu cluster EKS:

```bash
# Torne o script executável
chmod +x setup-kubectl.sh

# Execute o script
./setup-kubectl.sh
```

O script fará o seguinte:

- Verificar se você tem todas as dependências necessárias
- Obter o nome do cluster do estado do Terraform
- Configurar o kubectl para se conectar ao cluster EKS
- Testar a conexão com o cluster
- Configurar aliases úteis para kubectl (opcional)
- Instalar plugins úteis (opcional)

## Configuração Manual

Se preferir fazer a configuração manualmente:

1. Configure o kubectl para acessar seu cluster EKS:

```bash
aws eks update-kubeconfig --name <nome-do-cluster> --region <região-aws>
```

2. Verifique se a configuração funcionou:

```bash
kubectl get nodes
```

## Comandos Úteis do kubectl

### Comandos Básicos

```bash
# Listar todos os nós do cluster
kubectl get nodes

# Listar todos os pods em todos os namespaces
kubectl get pods --all-namespaces

# Listar pods em um namespace específico
kubectl get pods -n <namespace>

# Descrever um pod específico
kubectl describe pod <nome-do-pod> -n <namespace>

# Obter logs de um pod
kubectl logs <nome-do-pod> -n <namespace>

# Executar um comando em um pod
kubectl exec -it <nome-do-pod> -n <namespace> -- /bin/bash

# Listar serviços
kubectl get services --all-namespaces

# Obter informações detalhadas de um recurso em formato YAML
kubectl get pod <nome-do-pod> -n <namespace> -o yaml
```

### Namespaces Principais do Cluster

Nosso cluster EKS tem os seguintes namespaces principais:

- **istio-system**: Contém componentes do Istio (service mesh)
- **monitoring**: Contém ferramentas de monitoramento (Prometheus, Grafana, etc.)
- **cert-manager**: Gerenciamento de certificados SSL
- **application**: Namespace para aplicações de negócio

Para listar recursos em um namespace específico:

```bash
kubectl get all -n istio-system
kubectl get all -n monitoring
```

### Verificando a Saúde do Cluster

```bash
# Verificar status dos nós
kubectl get nodes
kubectl describe nodes

# Verificar pods com problemas
kubectl get pods --all-namespaces | grep -v Running

# Verificar eventos do cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Verificar uso de recursos
kubectl top nodes
kubectl top pods --all-namespaces
```

### Acessando Serviços

Para acessar serviços como Grafana, Kiali ou Jaeger, use o port-forward:

```bash
# Acessar Grafana (disponível em http://localhost:3000)
kubectl port-forward svc/grafana 3000:3000 -n monitoring

# Acessar Kiali (disponível em http://localhost:20001)
kubectl port-forward svc/kiali 20001:20001 -n istio-system

# Acessar Jaeger (disponível em http://localhost:16686)
kubectl port-forward svc/jaeger-query 16686:16686 -n monitoring
```

### Aliases Úteis

Para maior produtividade, adicione estes aliases ao seu arquivo de shell (~/.bashrc ou ~/.zshrc):

```bash
# Aliases do kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
# Aliases para namespaces específicos
alias k-monitoring='kubectl -n monitoring'
alias k-istio='kubectl -n istio-system'
alias k-app='kubectl -n application'
```

Depois, execute `source ~/.bashrc` ou `source ~/.zshrc` para aplicar as mudanças.

## Plugins Úteis para kubectl

O kubectl pode ser estendido com plugins úteis via [krew](https://krew.sigs.k8s.io/):

```bash
# Instalar krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# Adicionar krew ao PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Instalar plugins úteis
kubectl krew install ctx        # Gerenciar contextos facilmente
kubectl krew install ns         # Gerenciar namespaces facilmente
kubectl krew install tail       # Rastrear logs de múltiplos pods
kubectl krew install neat       # Limpar saídas de recursos
kubectl krew install resource-capacity  # Visualizar capacidade de recursos
kubectl krew install view-secret # Visualizar secrets decodificados
```

## Troubleshooting Comum

### Problemas de Conexão

Se você não conseguir se conectar ao cluster:

1. Verifique se suas credenciais AWS estão configuradas corretamente:

   ```bash
   aws sts get-caller-identity
   ```

2. Verifique se o cluster existe:

   ```bash
   aws eks list-clusters --region <região-aws>
   ```

3. Atualize seu kubeconfig:
   ```bash
   aws eks update-kubeconfig --name <nome-do-cluster> --region <região-aws>
   ```

### Pods em estado "Pending" ou "Crashing"

1. Verificar detalhes do pod:

   ```bash
   kubectl describe pod <nome-do-pod> -n <namespace>
   ```

2. Verificar logs do pod:

   ```bash
   kubectl logs <nome-do-pod> -n <namespace>
   ```

3. Verificar eventos do cluster:
   ```bash
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

### Namespace preso em estado "Terminating"

```bash
kubectl get namespace <namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
```

## Recursos Adicionais

- [Documentação Oficial do kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Cheat Sheet do kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Documentação do EKS](https://docs.aws.amazon.com/eks/)
