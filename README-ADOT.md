# AWS Distro for OpenTelemetry (ADOT) no EKS

Este documento explica como utilizar o AWS Distro for OpenTelemetry (ADOT) que foi configurado como um addon EKS pelo Terraform.

## O que é o AWS Distro for OpenTelemetry?

O AWS Distro for OpenTelemetry (ADOT) é uma distribuição segura e pronta para produção do projeto OpenTelemetry da Cloud Native Computing Foundation (CNCF). Ele fornece APIs, bibliotecas e agentes para coletar métricas e traces (dados de telemetria) para aplicações.

O ADOT inclui os seguintes componentes:

- **Collector**: Recebe, processa e exporta dados de telemetria
- **Operator**: Gerencia o ciclo de vida dos coletores
- **Instrumentação**: Bibliotecas para instrumentar código

## O que foi configurado pelo Terraform

O Terraform configurou:

1. O addon ADOT no cluster EKS (com a versão mais recente compatível com a versão do Kubernetes)
2. Uma política IAM com as permissões necessárias para o ADOT
3. Uma função IAM (role) que pode ser assumida pelo ADOT para acessar serviços AWS
4. Anotação no Service Account existente do ADOT para utilizar a função IAM criada

## Como usar o ADOT

### 1. Verificar a instalação

```bash
# Verificar o status do addon
kubectl get deployment -n opentelemetry-operator-system

# Verificar se o CRD (Custom Resource Definition) foi criado
kubectl get crd | grep opentelemetry

# Verificar se o service account tem a anotação IAM correta
kubectl get serviceaccount opentelemetry-operator -n opentelemetry-operator-system -o yaml
```

### 2. Configurar um coletor

Crie um arquivo `collector.yaml`:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: adot-collector
spec:
  mode: deployment
  serviceAccount: opentelemetry-operator
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus:
        config:
          scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true

    processors:
      batch:
        timeout: 1s
      
    exporters:
      awsxray:
        region: "${var.aws_region}"
      awsemf:
        region: "${var.aws_region}"
        namespace: EKSCluster
      logging:
        loglevel: debug

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [awsxray, logging]
        metrics:
          receivers: [otlp, prometheus]
          processors: [batch]
          exporters: [awsemf, logging]
```

Aplique a configuração:

```bash
kubectl apply -f collector.yaml
```

### 3. Instrumentar suas aplicações

#### Java com OpenTelemetry

Adicione as dependências:

```xml
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
    <version>1.29.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
    <version>1.29.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
    <version>1.29.0</version>
</dependency>
```

Configure o exportador:

```java
OtlpGrpcSpanExporter exporter = OtlpGrpcSpanExporter.builder()
    .setEndpoint("http://adot-collector:4317")
    .build();

SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
    .addSpanProcessor(SimpleSpanProcessor.create(exporter))
    .build();

OpenTelemetrySdk openTelemetry = OpenTelemetrySdk.builder()
    .setTracerProvider(tracerProvider)
    .build();

Tracer tracer = openTelemetry.getTracer("app.name");
```

#### Python com OpenTelemetry

Instale as bibliotecas:

```bash
pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp
```

Configure o exportador:

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

otlp_exporter = OTLPSpanExporter(endpoint="adot-collector:4317", insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Crie spans
with tracer.start_as_current_span("main"):
    print("Hello world!")
```

## Visualização de métricas e traces

- **X-Ray**: Para visualizar traces no AWS X-Ray
- **CloudWatch**: Para visualizar métricas no CloudWatch
- **Amazon Managed Service for Prometheus**: Para armazenar e consultar métricas
- **Amazon Managed Grafana**: Para criar dashboards

## Verificar a versão instalada do ADOT

Para saber qual versão do ADOT está instalada no cluster:

```bash
# Verificar a versão do addon
kubectl describe addon adot -n kube-system | grep Version

# Listar todas as versões disponíveis para seu cluster EKS
aws eks describe-addon-versions \
    --addon-name adot \
    --kubernetes-version $(aws eks describe-cluster --name seu-cluster-eks --query "cluster.version" --output text)
```

## Solução de problemas

### Verificar status do addon

```bash
kubectl describe addon adot -n kube-system
```

### Verificar logs do coletor

```bash
kubectl logs -l app=adot-collector
```

### Verificar a configuração IAM

```bash
aws iam get-role --role-name <nome-do-cluster>-adot-role
aws iam list-attached-role-policies --role-name <nome-do-cluster>-adot-role
```
