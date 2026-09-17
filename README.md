# Secure Legacy Hospital — ambiente inicial

O fluxo é **Traefik → ModSecurity/OWASP CRS → Authentik Proxy Outpost → aplicação**. Agendamento e Exames não publicam portas: apenas o Proxy Provider do Authentik pode alcançá-las.

As aplicações escrevem logs JSON em volumes próprios; o OpenTelemetry Collector acompanha esses arquivos, bem como o access log JSON do Traefik, e envia ambos ao Graylog por Syslog TCP. 
Traces e métricas seguem via OTLP para o mesmo Collector; ele exporta traces ao Tempo e expõe métricas para o Prometheus. O Grafana consulta ambos.

## Composes segmentados

| Arquivo | Domínio | Uso isolado |
| --- | --- | --- |
| `compose.edge.yaml` | Traefik, WAF e backend de validação | Atualizar borda sem parar aplicações. |
| `compose.identity.yaml` | Authentik, PostgreSQL, Redis e Proxy Outpost | Operar IAM sem alterar telemetria. |
| `compose.observability.yaml` | Graylog, OpenSearch, Collector, Tempo, Prometheus e Grafana | Operar observabilidade de forma independente. |
| `compose.app-agendamento.yaml` | Aplicação de agendamento | Publicar/reiniciar somente agendamento. |
| `compose.app-exames.yaml` | Aplicação de exames | Publicar/reiniciar somente exames. |
| `compose.yaml` | Orquestrador | Sobe todos os anteriores. |

Para subir tudo: `docker compose up -d --build`.

Para operar apenas um domínio, mantenha o mesmo nome de projeto e sempre some o arquivo comum: `docker compose -p secure-legacy-hospital -f compose.common.yaml -f compose.app-agendamento.yaml up -d --build`.

## Preparação

1. Copie `.env.example` para `.env` e gere todos os segredos. `GRAYLOG_ROOT_PASSWORD_SHA2` é o SHA-256 da senha de admin do Graylog.
2. Em Linux/WSL, ajuste `vm.max_map_count` para pelo menos `262144`, exigido pelo OpenSearch.
3. Inclua no arquivo `hosts` os nomes `auth.hospital.lab`, `agendamento.hospital.lab`, `exames.hospital.lab`, `graylog.hospital.lab`, `grafana.hospital.lab` e `prometheus.hospital.lab`, todos apontando para `127.0.0.1`.

## Subida

1. Inicie Authentik: `docker compose up -d authentik-postgres authentik-redis authentik-server authentik-worker`.
2. Abra `https://auth.hospital.lab/` e conclua o bootstrap. O navegador exibirá aviso por ser certificado autoassinado.
3. No Authentik, crie um **Proxy Provider** por aplicação e associe os dois a um **Proxy Outpost**. Use:
   - Agendamento: external host `https://agendamento.hospital.lab`, upstream `http://app-agendamento:8080`.
   - Exames: external host `https://exames.hospital.lab`, upstream `http://app-exames:8080`.
4. Copie o token do Outpost para `AUTHENTIK_OUTPOST_TOKEN` no `.env`.
5. Valide com `docker compose config` e inicie: `docker compose up -d --build`.
6. No Graylog, crie um **Global Syslog TCP Input** na porta `1514`. Esse é o destino do pipeline de logs do OpenTelemetry Collector.

## Endereços

| Serviço | Endereço |
| --- | --- |
| Authentik | `https://auth.hospital.lab/` |
| Agendamento | `https://agendamento.hospital.lab/` |
| Exames | `https://exames.hospital.lab/` |
| Graylog | `https://graylog.hospital.lab/` |
| Grafana | `https://grafana.hospital.lab/` |
| Prometheus | `https://prometheus.hospital.lab/` |

