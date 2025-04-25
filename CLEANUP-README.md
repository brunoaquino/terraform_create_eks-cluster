# Guia de Limpeza de Recursos do EKS

Este documento explica como deletar corretamente os recursos do Kubernetes antes de destruir o cluster EKS via Terraform.

## Por que é necessário limpar recursos manualmente?

Ao tentar destruir um cluster EKS usando `terraform destroy`, você pode encontrar os seguintes problemas:

1. **Recursos pendentes:** Recursos do Kubernetes (como LoadBalancers, Volumes Persistentes) que continuam existindo na AWS mesmo após o comando de destruição
2. **Falha na exclusão de VPC:** VPCs não podem ser excluídas enquanto houver recursos associados a elas
3. **Tempo limite:** Recursos que demoram muito para serem destruídos podem fazer com que o Terraform atinja tempos limite
4. **Namespaces protegidos:** Erro ao tentar deletar namespaces protegidos como "default"

Para evitar esses problemas, é recomendável limpar os recursos Kubernetes antes de executar `terraform destroy`.

## Método 1: Utilizando o Script de Limpeza Automatizada

Fornecemos um script `eks-cleanup.sh` que automatiza o processo de limpeza do cluster:

```bash
# Torne o script executável
chmod +x eks-cleanup.sh

# Execute o script
./eks-cleanup.sh
```

O script:

1. Reduz réplicas para zero para evitar novas criações
2. Remove serviços e ingressos para liberar load balancers
3. Remove workloads (deployments, statefulsets, etc.)
4. Desinstala releases Helm
5. Remove CRDs e suas instâncias
6. Remove PVs e PVCs
7. Remove secrets e configmaps
8. Remove namespaces
9. Tenta resolver namespaces travados
10. Verifica recursos remanescentes

**Importante:** O script foi atualizado para preservar automaticamente os namespaces do sistema (`kube-system`, `kube-public`, `kube-node-lease` e `default`), evitando erros comuns durante a destruição.

## Ferramenta Adicional: Script de Limpeza de CRDs

Também fornecemos um script específico para lidar com CRDs (Custom Resource Definitions), que frequentemente causam problemas durante a remoção do cluster:

```bash
# Torne o script executável
chmod +x eks-cleanup-crds.sh

# Execute o script
./eks-cleanup-crds.sh
```

Este script oferece um menu interativo para:

1. Listar todos os CRDs no cluster
2. Limpar um CRD específico (removendo todas as instâncias e finalizadores)
3. Limpar todos os CRDs (operação que pode demorar)
4. Verificar e corrigir CRDs travados no estado "Terminating"

Use esta ferramenta se encontrar CRDs travados que o script principal não consiga remover.

## Método 2: Limpeza Manual Passo a Passo

Se preferir um controle mais granular ou se o script automatizado encontrar problemas, você pode seguir estes passos manualmente:

### 1. Reduzir réplicas para evitar criação de novos recursos

```bash
# Listar todos os namespaces
kubectl get ns

# Para cada namespace relevante (exceto os do sistema), reduzir réplicas para zero
for ns in $(kubectl get ns -o name | cut -d/ -f2 | grep -v "kube-system" | grep -v "kube-public" | grep -v "kube-node-lease" | grep -v "default"); do
  kubectl scale deployment --all --replicas=0 -n $ns
  kubectl scale statefulset --all --replicas=0 -n $ns
done
```

### 2. Remover serviços com Load Balancers

```bash
# Listar serviços em todos os namespaces
kubectl get svc --all-namespaces | grep LoadBalancer

# Deletar serviços que estão criando Load Balancers
kubectl delete svc nome-do-servico -n namespace
```

### 3. Remover recursos Istio (se aplicável)

```bash
# Remover virtual services
kubectl delete virtualservices.networking.istio.io --all --all-namespaces

# Remover gateways
kubectl delete gateways.networking.istio.io --all --all-namespaces
```

### 4. Desinstalar releases Helm

```bash
# Listar todas as releases Helm em um namespace
helm list -n namespace

# Desinstalar uma release específica
helm uninstall nome-da-release -n namespace

# Desinstalar todas as releases em um namespace
helm list -n namespace -q | xargs -L1 helm uninstall -n namespace
```

### 5. Remover PVCs e PVs

```bash
# Listar PVCs em todos os namespaces
kubectl get pvc --all-namespaces

# Deletar todos os PVCs em um namespace
kubectl delete pvc --all -n namespace

# Depois que os PVCs forem deletados, verifique e delete os PVs
kubectl get pv
kubectl delete pv --all
```

### 6. Remover namespaces

```bash
# Deletar um namespace específico (IMPORTANTE: não tente deletar namespaces do sistema)
# Lista de namespaces que NÃO devem ser deletados: kube-system, kube-public, kube-node-lease, default
kubectl delete ns nome-do-namespace
```

### 7. Resolver namespaces travados

Se um namespace ficar preso no estado "Terminating":

```bash
# Obter o namespace em formato JSON
kubectl get namespace namespace-travado -o json > ns.json

# Editar o arquivo para remover finalizers
# Usando jq para automatizar:
cat ns.json | jq '.spec.finalizers = []' > ns-modified.json

# Aplicar a alteração diretamente na API
kubectl replace --raw "/api/v1/namespaces/namespace-travado/finalize" -f ns-modified.json
```

## Erros Comuns e Soluções

### 1. Erro ao tentar deletar o namespace "default"

```
Error: default failed to delete kubernetes resource: namespaces "default" is forbidden: this namespace may not be deleted
```

**Solução:** O namespace "default" é protegido e não pode ser deletado. Os scripts atualizados já evitam isso automaticamente. Se você estiver executando comandos manualmente, simplesmente pule este namespace.

### 2. Namespace preso em "Terminating"

```bash
kubectl get namespace <namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
```

### 3. PVCs não são deletados

```bash
# Verificar se há pods usando o PVC
kubectl describe pvc <nome-do-pvc> -n <namespace>

# Forçar a exclusão do PVC (use com cautela)
kubectl patch pvc <nome-do-pvc> -n <namespace> -p '{"metadata":{"finalizers":null}}'
```

### 4. CRDs travados impedindo exclusão

Use o script `eks-cleanup-crds.sh` para lidar com CRDs problemáticos. Alternativamente:

```bash
# Listar CRDs travados
kubectl get crd -o json | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | .metadata.name'

# Remover finalizadores de um CRD
kubectl get crd <nome-do-crd> -o json | jq 'del(.metadata.finalizers)' | kubectl replace --raw "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/<nome-do-crd>/status" -f -
```

### 5. Load Balancers persistem após a exclusão do serviço

Verifique no console AWS se os load balancers ainda existem e exclua-os manualmente se necessário.

## Verificação Final Antes do Terraform Destroy

Após a limpeza, verifique se não há recursos remanescentes que possam impedir a destruição:

```bash
# Listar namespaces (deve mostrar apenas os namespaces do sistema)
kubectl get ns

# Verificar se há PVs ou PVCs restantes
kubectl get pv,pvc --all-namespaces

# Verificar serviços com Load Balancers
kubectl get svc --all-namespaces | grep LoadBalancer
```

## Dicas para Evitar Problemas

1. **Verifique finalizers:** Recursos com finalizers podem ficar presos. Use `kubectl get <recurso> -o yaml` para verificar finalizers e removê-los se necessário.

2. **Timeout mais longo:** Se usar terraform destroy, considere aumentar os timeouts:

   ```bash
   terraform destroy -timeout=30m
   ```

3. **Verificar recursos AWS:** Mesmo após limpar os recursos Kubernetes, verifique no console AWS se há recursos pendentes:

   - Load Balancers
   - Volumes EBS
   - Interfaces de rede
   - Security Groups

4. **Destaque para serviços no kube-system:** Cuidado especial com serviços no namespace kube-system que podem criar recursos AWS.

5. **Não force a exclusão de namespaces do sistema:** Os namespaces `kube-system`, `kube-public`, `kube-node-lease` e `default` são essenciais para o Kubernetes e não devem ser removidos manualmente.

## Após a Limpeza

Depois de limpar todos os recursos Kubernetes, você pode prosseguir com a destruição do cluster EKS:

```bash
terraform destroy
```

A limpeza prévia aumentará significativamente as chances de uma destruição bem-sucedida e sem recursos órfãos na AWS.
