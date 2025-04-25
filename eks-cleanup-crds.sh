#!/bin/bash

# Script para limpar CRDs (Custom Resource Definitions) que muitas vezes ficam travados
# Use este script se os CRDs estão impedindo a remoção do cluster

set -e

echo "=== LIMPEZA DE CRDs DO KUBERNETES ==="
echo "Este script vai remover os Custom Resource Definitions (CRDs) e suas instâncias"
echo "ATENÇÃO: Isso pode afetar o funcionamento de operadores e outros componentes avançados do Kubernetes"
echo ""
echo "Pressione CTRL+C para cancelar ou ENTER para continuar"
read -p ""

# Verifica se jq está instalado
if ! command -v jq &> /dev/null; then
  echo "❌ Este script requer o jq. Por favor, instale-o primeiro:"
  echo "Mac: brew install jq"
  echo "Linux: apt-get install jq ou yum install jq"
  exit 1
fi

# Lista todos os CRDs
list_all_crds() {
  echo "Listando todos os Custom Resource Definitions..."
  kubectl get crd -o name
}

# Limpa todas as instâncias de um CRD específico
clean_crd_instances() {
  local crd=$1
  local crd_name=$(echo $crd | cut -d/ -f2)
  
  echo "=== Processando $crd_name ==="
  
  # Verificar se existem instâncias deste CRD
  if ! kubectl get $crd_name --all-namespaces -o name 2>/dev/null | grep -q .; then
    echo "Nenhuma instância encontrada para $crd_name"
    return
  fi
  
  # Listar todas as instâncias
  echo "Instâncias de $crd_name encontradas:"
  kubectl get $crd_name --all-namespaces
  
  # Para cada instância, remover finalizadores e depois deletar
  kubectl get $crd_name --all-namespaces -o json | jq -r '.items[] | [.metadata.name, .metadata.namespace] | @tsv' | \
  while read -r name namespace; do
    if [ "$namespace" = "null" ]; then
      echo "Removendo finalizadores de $crd_name/$name (recurso global)..."
      kubectl get $crd_name $name -o json | jq 'del(.metadata.finalizers)' | kubectl replace --raw "/apis/$(kubectl get $crd_name $name -o jsonpath='{.apiVersion}')/$crd_name/$name/status" -f - 2>/dev/null || true
      echo "Deletando $crd_name/$name..."
      kubectl delete $crd_name $name --wait=false
    else
      echo "Removendo finalizadores de $crd_name/$name em namespace $namespace..."
      kubectl get $crd_name $name -n $namespace -o json | jq 'del(.metadata.finalizers)' | kubectl replace --raw "/apis/$(kubectl get $crd_name $name -n $namespace -o jsonpath='{.apiVersion}')/namespaces/$namespace/$crd_name/$name/status" -f - 2>/dev/null || true
      echo "Deletando $crd_name/$name em namespace $namespace..."
      kubectl delete $crd_name $name -n $namespace --wait=false
    fi
  done
  
  # Esperar um momento para que as exclusões de instâncias sejam processadas
  echo "Aguardando a exclusão de instâncias..."
  sleep 3
}

# Remover finalizadores de um CRD específico
clean_crd_finalizers() {
  local crd=$1
  local crd_name=$(echo $crd | cut -d/ -f2)
  
  echo "Removendo finalizadores do CRD $crd_name..."
  kubectl get crd $crd_name -o json | jq 'del(.metadata.finalizers)' | kubectl replace --raw "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/$crd_name/status" -f - 2>/dev/null || true
}

# Deletar um CRD específico
delete_crd() {
  local crd=$1
  local crd_name=$(echo $crd | cut -d/ -f2)
  
  echo "Deletando CRD $crd_name..."
  kubectl delete crd $crd_name --wait=false
}

# Verificar CRDs travados em estado de exclusão
check_stuck_crds() {
  echo "Verificando CRDs travados..."
  kubectl get crd -o json | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | .metadata.name' | \
  while read -r crd_name; do
    echo "CRD travado encontrado: $crd_name"
    # Tentar remover finalizadores
    kubectl get crd $crd_name -o json | jq 'del(.metadata.finalizers)' | kubectl replace --raw "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/$crd_name/status" -f - 2>/dev/null || true
  done
}

# Menu para operações
show_menu() {
  echo ""
  echo "=== MENU DE LIMPEZA DE CRDs ==="
  echo "1. Listar todos os CRDs"
  echo "2. Limpar um CRD específico (instâncias e finalizers)"
  echo "3. Limpar todos os CRDs (pode demorar)"
  echo "4. Verificar e corrigir CRDs travados"
  echo "0. Sair"
  echo ""
  read -p "Escolha uma opção (0-4): " option
  
  case $option in
    1)
      list_all_crds
      show_menu
      ;;
    2)
      list_all_crds
      echo ""
      read -p "Digite o nome do CRD para limpar (ex: crd/myresource.example.com): " crd_to_clean
      clean_crd_instances $crd_to_clean
      clean_crd_finalizers $crd_to_clean
      delete_crd $crd_to_clean
      show_menu
      ;;
    3)
      echo "⚠️ Isso vai tentar remover TODOS os CRDs e suas instâncias."
      read -p "Tem certeza? (y/n): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for crd in $(kubectl get crd -o name); do
          clean_crd_instances $crd
          clean_crd_finalizers $crd
          delete_crd $crd
        done
        echo "Operação concluída. Verificando CRDs remanescentes..."
        list_all_crds
      fi
      show_menu
      ;;
    4)
      check_stuck_crds
      show_menu
      ;;
    0)
      echo "Saindo..."
      exit 0
      ;;
    *)
      echo "Opção inválida. Por favor, tente novamente."
      show_menu
      ;;
  esac
}

# Iniciar o programa
echo "Este script ajuda a remover CRDs que podem ficar travados durante a limpeza do cluster."
show_menu 