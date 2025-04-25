#!/bin/bash

# Script para deletar recursos do cluster EKS antes da destruição via Terraform
# Execute este script antes de usar terraform destroy para evitar problemas com recursos pendentes

set -e

echo "=== LIMPEZA DE RECURSOS DO EKS ==="
echo "Este script vai remover recursos do Kubernetes para facilitar a destruição do cluster via Terraform"
echo "ATENÇÃO: Isso vai DELETAR TODOS os recursos do cluster. Os dados serão PERDIDOS."
echo ""
echo "Pressione CTRL+C para cancelar ou ENTER para continuar"
read -p ""

# Lista de namespaces do sistema a serem protegidos
SYSTEM_NAMESPACES=("kube-system" "kube-public" "kube-node-lease" "default")

# Verificar se um namespace é do sistema
is_system_namespace() {
  local ns=$1
  for sys_ns in "${SYSTEM_NAMESPACES[@]}"; do
    if [[ "$ns" == "$sys_ns" ]]; then
      return 0  # É namespace do sistema
    fi
  done
  return 1  # Não é namespace do sistema
}

# Função para esperar até que todos os recursos do tipo especificado sejam deletados
wait_for_deletion() {
  local resource_type=$1
  local namespace=${2:-""}
  local ns_option=""
  
  if [ -n "$namespace" ]; then
    ns_option="-n $namespace"
  else
    ns_option="--all-namespaces"
  fi
  
  echo "Aguardando a exclusão de $resource_type $ns_option..."
  
  while true; do
    local resources=$(kubectl get $resource_type $ns_option -o name 2>/dev/null || echo "")
    if [ -z "$resources" ]; then
      echo "✅ Todos os recursos $resource_type foram excluídos"
      break
    fi
    echo "⏳ Ainda aguardando a exclusão de $(echo "$resources" | wc -l | xargs) $resource_type..."
    sleep 5
  done
}

# Função para remover finalizadores de um recurso travado
remove_finalizers() {
  local resource_type=$1
  local resource_name=$2
  local namespace=${3:-""}
  local ns_option=""
  
  if [ -n "$namespace" ]; then
    ns_option="-n $namespace"
  fi
  
  echo "Removendo finalizadores de $resource_type/$resource_name $ns_option..."
  
  kubectl get $resource_type $resource_name $ns_option -o json | \
    jq '.metadata.finalizers = []' | \
    kubectl replace --raw "/api/v1/$resource_type/$resource_name/finalize" -f -
}

# Função para listar e remover recursos específicos
delete_resources() {
  local resource_type=$1
  local namespace=${2:-""}
  local ns_option=""
  local all_ns_message=""
  
  if [ -n "$namespace" ]; then
    ns_option="-n $namespace"
    all_ns_message="no namespace $namespace"
  else
    ns_option="--all-namespaces"
    all_ns_message="em todos os namespaces"
  fi
  
  echo "Listando $resource_type $all_ns_message..."
  kubectl get $resource_type $ns_option
  
  echo "Deletando todos os $resource_type $all_ns_message..."
  kubectl delete $resource_type --all $ns_option
  
  # Aguardar a exclusão completa
  wait_for_deletion $resource_type $namespace
}

# 1. Reduzir réplicas para evitar novas criações
echo "=== Reduzindo réplicas de Deployments, StatefulSets e ReplicaSets ==="
echo "Atualizando deployments..."
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  kubectl get deployments -n $ns -o name 2>/dev/null | xargs -r -I{} kubectl scale {} --replicas=0 -n $ns
done

echo "Atualizando statefulsets..."
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  kubectl get statefulsets -n $ns -o name 2>/dev/null | xargs -r -I{} kubectl scale {} --replicas=0 -n $ns
done

echo "Atualizando replicasets..."
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  kubectl get replicasets -n $ns -o name 2>/dev/null | xargs -r -I{} kubectl scale {} --replicas=0 -n $ns
done

# 2. Deletar objetos principais - primeiro os objetos de nível mais alto
echo "=== Removendo recursos de mais alto nível ==="
# Remover ingresses e serviços para liberar load balancers
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  
  echo "Deletando ingresses no namespace $ns..."
  kubectl delete ingress --all -n $ns 2>/dev/null || true
  
  echo "Deletando gateways no namespace $ns..."
  kubectl delete gateways.networking.istio.io --all -n $ns 2>/dev/null || true
  
  echo "Deletando virtualservices no namespace $ns..."
  kubectl delete virtualservices.networking.istio.io --all -n $ns 2>/dev/null || true
  
  echo "Deletando services no namespace $ns..."
  # Deletar todos os serviços exceto kubernetes
  kubectl get services -n $ns -o name | grep -v "service/kubernetes" | xargs -r kubectl delete -n $ns
done

# 3. Remover workloads
echo "=== Removendo workloads ==="
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  
  echo "Trabalhando no namespace $ns..."
  
  echo "Deletando deployments..."
  kubectl delete deployments --all -n $ns 2>/dev/null || true
  
  echo "Deletando statefulsets..."
  kubectl delete statefulsets --all -n $ns 2>/dev/null || true
  
  echo "Deletando daemonsets..."
  kubectl delete daemonsets --all -n $ns 2>/dev/null || true
  
  echo "Deletando jobs..."
  kubectl delete jobs --all -n $ns 2>/dev/null || true
  
  echo "Deletando cronjobs..."
  kubectl delete cronjobs --all -n $ns 2>/dev/null || true
  
  echo "Deletando replicasets..."
  kubectl delete replicasets --all -n $ns 2>/dev/null || true
done

# 4. Remover aplicações Helm
echo "=== Removendo releases Helm ==="
if command -v helm &> /dev/null; then
  for ns in $(kubectl get ns -o name | cut -d/ -f2); do
    # Pular namespaces do sistema
    if is_system_namespace "$ns"; then
      echo "Pulando namespace de sistema: $ns"
      continue
    fi
    
    echo "Listando releases Helm no namespace $ns..."
    helm list -n $ns
    
    echo "Removendo todas as releases Helm no namespace $ns..."
    helm list -n $ns -q | xargs -r helm uninstall -n $ns
  done
else
  echo "⚠️ Helm não encontrado, pulando remoção de releases Helm"
fi

# 5. Remover recursos customizados (CRDs)
echo "=== Removendo Custom Resource Definitions (CRDs) e suas instâncias ==="
# Primeiro, remover instâncias de CRDs
for crd in $(kubectl get crd -o name 2>/dev/null || echo ""); do
  crd_name=$(echo $crd | cut -d/ -f2)
  echo "Removendo instâncias de $crd_name..."
  kubectl delete $crd_name --all --all-namespaces 2>/dev/null || true
done

# Depois, remover os CRDs em si
echo "Removendo CRDs..."
kubectl delete crd --all 2>/dev/null || true

# 6. Remover Persistent Volumes e Claims
echo "=== Removendo PersistentVolumes e PersistentVolumeClaims ==="
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  
  echo "Deletando PVCs no namespace $ns..."
  kubectl delete pvc --all -n $ns 2>/dev/null || true
done

echo "Deletando todos os PVs..."
kubectl delete pv --all 2>/dev/null || true

# 7. Remover secrets e configmaps
echo "=== Removendo Secrets e ConfigMaps ==="
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Pulando namespace de sistema: $ns"
    continue
  fi
  
  echo "Deletando Secrets no namespace $ns..."
  kubectl delete secrets --all -n $ns 2>/dev/null || true
  
  echo "Deletando ConfigMaps no namespace $ns..."
  kubectl delete configmaps --all -n $ns 2>/dev/null || true
done

# 8. Remover namespaces
echo "=== Removendo Namespaces ==="
# Listar todos os namespaces exceto os do sistema
kubectl get ns -o name | while read ns; do
  ns_name=$(echo $ns | cut -d/ -f2)
  
  # Pular namespaces do sistema
  if is_system_namespace "$ns_name"; then
    echo "Preservando namespace de sistema: $ns_name"
    continue
  fi
  
  echo "Deletando namespace $ns_name..."
  kubectl delete ns $ns_name --wait=false
done

# 9. Verificar namespaces travados e tentar resolver
echo "=== Verificando Namespaces travados ==="
for ns in $(kubectl get ns | grep Terminating | awk '{print $1}'); do
  # Pular namespaces do sistema
  if is_system_namespace "$ns"; then
    echo "Namespace de sistema $ns está travado, mas não será modificado para segurança"
    continue
  fi
  
  echo "Namespace $ns está travado em estado Terminating, tentando remover finalizadores..."
  kubectl get namespace $ns -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - || true
done

# 10. Mostrar recursos remanescentes
echo "=== Verificando recursos remanescentes ==="
echo "Namespaces:"
kubectl get ns

echo "Todos os recursos restantes em namespaces não-sistema:"
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  # Pular namespaces do sistema na listagem final
  if is_system_namespace "$ns"; then
    continue
  fi
  
  echo "Recursos em $ns:"
  kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n $ns
done

echo "=== LIMPEZA CONCLUÍDA ==="
echo "A maioria dos recursos do Kubernetes foi removida. Agora é mais seguro executar 'terraform destroy'."
echo "Recursos que não puderam ser excluídos automaticamente podem precisar de intervenção manual."
echo "NOTA: Namespaces do sistema (${SYSTEM_NAMESPACES[*]}) foram preservados para segurança." 