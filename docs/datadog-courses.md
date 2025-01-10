
# Datadog 101: Site Reliability Engineer

## APM

### Examine the configured service

Already instrumented docker-compose.yaml

```yaml
version: '3'
services:
  datadog:
    image: 'datadog/agent:7.31.1'
    environment:
      - DD_API_KEY
      - DD_HOSTNAME=dd101-sre-host
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_DOCKER_LABELS_AS_TAGS={"my.custom.label.team":"team"}
      - DD_TAGS='env:dd101-sre'
      - DD_APM_NON_LOCAL_TRAFFIC=true
    ports:
      - 127.0.0.1:8126:8126/tcp
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
  discounts:
    environment:
      - FLASK_APP=discounts.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
      - DD_SERVICE=discounts-service
      - DD_ENV=dd101-sre
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_SERVICE_MAPPING=postgres:database
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/discounts-fixed:2.2.0'
    ports:
      - '5001:5001'
    command:
      [
        sh,
        -c,
        'ddtrace-run flask run --port=5001 --host=0.0.0.0'
      ]
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'discounts-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'discounts'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "discounts-service"}]'
  frontend:
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/storefront-fixed:2.2.0'
    ports:
      - '3000:3000'
    depends_on:
      - datadog
      - discounts
      - advertisements
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'store-frontend'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'frontend'
      com.datadoghq.ad.logs: '[{"source": "ruby", "service": "store-frontend"}]'
  advertisements:
    environment:
      - FLASK_APP=ads.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/advertisements-fixed:2.2.0'
    ports:
      - '5002:5002'
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'advertisements-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'advertisements'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "advertisements-service"}]'
  db:
    image: postgres:11-alpine
    restart: always
    environment:
      - POSTGRES_PASSWORD
      - POSTGRES_USER
    ports:
      - '5432:5432'
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'database'
      com.datadoghq.tags.version: '11.12'
      my.custom.label.team: 'database'
      com.datadoghq.ad.check_names: '["postgres"]'
      com.datadoghq.ad.init_configs: '[{}]'
      com.datadoghq.ad.instances: '[{"host":"%%host%%", "port":5432,"username":"datadog","password":"datadog"}]'
      com.datadoghq.ad.logs: '[{"source": "postgresql", "service": "database"}]'
    volumes:
      - /root/postgres:/var/lib/postgresql/data
      - /root/dd_agent.sql:/docker-entrypoint-initdb.d/dd_agent.sql
  puppeteer:
    image: buildkite/puppeteer:10.0.0
    volumes:
      - /root/puppeteer-mobile.js:/puppeteer.js
      - /root/puppeteer.sh:/puppeteer.sh
    environment:
      - STOREDOG_URL
      - PUPPETEER_TIMEOUT
    depends_on:
      - frontend
    command: bash puppeteer.sh
```

Review the agent:

docker-compose exec datadog agent status

### Explore the APM wizard

DD_SERVICE="discounts" DD_ENV="dd101sre" DD_LOGS_INJECTION=true DD_TRACE_SAMPLE_RATE="1" DD_PROFILING_ENABLED=true ddtrace-run python my_app.py

### Explore traces in Datadog

Before talking about APM the logs are required

On the discounts-service service page, scroll down to Resources. Here you will see the service's application endpoints that APM traced. This service has one endpoint, GET /discount

### Traveerse between APM traces and logs

When the ddtrace library finds the environment variable DD_LOGS_INJECTION=true, it automatically injects tracing data into the log lines and formats the output as JSON

### Trace all the services

cp /root/docker-compose-complete.yml /root/lab/docker-compose.yml

new docker-compose.yaml with new variables

```yaml
version: '3'
services:
  datadog:
    image: 'datadog/agent:7.31.1'
    environment:
      - DD_API_KEY
      - DD_HOSTNAME=dd101-sre-host
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_DOCKER_LABELS_AS_TAGS={"my.custom.label.team":"team"}
      - DD_TAGS='env:dd101-sre'
      - DD_APM_NON_LOCAL_TRAFFIC=true
    ports:
      - 127.0.0.1:8126:8126/tcp
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
  discounts:
    environment:
      - FLASK_APP=discounts.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
      - DD_SERVICE=discounts-service
      - DD_ENV=dd101-sre
      - DD_VERSION=2.2.0
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_SERVICE_MAPPING=postgres:database
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/discounts-fixed:2.2.0'
    command:
      [
        sh,
        -c,
        'ddtrace-run flask run --port=5001 --host=0.0.0.0',
      ]
    ports:
      - '5001:5001'
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'discounts-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'discounts'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "discounts-service"}]'
  frontend:
    environment:
      - DD_SERVICE=store-frontend
      - DD_ENV=dd101-sre
      - DD_VERSION=2.2.0
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/storefront-fixed:2.2.0'
    command: sh docker-entrypoint.sh
    ports:
      - '3000:3000'
    depends_on:
      - datadog
      - discounts
      - advertisements
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'store-frontend'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'frontend'
      com.datadoghq.ad.logs: '[{"source": "ruby", "service": "store-frontend"}]'
  advertisements:
    environment:
      - FLASK_APP=ads.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
      - DD_SERVICE=advertisements-service
      - DD_ENV=dd101-sre
      - DD_VERSION=2.2.0
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_SERVICE_MAPPING=postgres:database
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/advertisements-fixed:2.2.0'
    command:
      [
        sh,
        -c,
        'ddtrace-run flask run --port=5002 --host=0.0.0.0',
      ]
    ports:
      - '5002:5002'
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'advertisements-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'advertisements'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "advertisements-service"}]'
  db:
    image: postgres:11-alpine
    restart: always
    environment:
      - POSTGRES_PASSWORD
      - POSTGRES_USER
    ports:
      - '5432:5432'
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'database'
      com.datadoghq.tags.version: '11.12'
      my.custom.label.team: 'database'
      com.datadoghq.ad.check_names: '["postgres"]'
      com.datadoghq.ad.init_configs: '[{}]'
      com.datadoghq.ad.instances: '[{"host":"%%host%%", "port":5432,"username":"datadog","password":"datadog"}]'
      com.datadoghq.ad.logs: '[{"source": "postgresql", "service": "database"}]'
    volumes:
      - /root/postgres:/var/lib/postgresql/data
      - /root/dd_agent.sql:/docker-entrypoint-initdb.d/dd_agent.sql
  puppeteer:
    image: buildkite/puppeteer:10.0.0
    volumes:
      - /root/puppeteer-mobile.js:/puppeteer.js
      - /root/puppeteer.sh:/puppeteer.sh
    environment:
      - STOREDOG_URL
      - PUPPETEER_TIMEOUT
    depends_on:
      - frontend
    command: bash puppeteer.sh

```

docker-compose down && docker-compose up -d

run the agent status in docker compose

docker-compose exec datadog agent status | grep "APM Agent" -A26

### SREs and Continuous Profiling

APM -> Profile

## NPM

NPM is built on eBPF (https://ebpf.io/), which enables detailed visibility into network flows at the Linux kernel level. Consequently, NPM is powerful and efficient with extremely low overhead

### Enabling NPM

docker-compose file with NPM enabled

```yaml
version: '3'
services:
  datadog:
    image: 'datadog/agent:7.31.1'
    environment:
      - DD_API_KEY
      - DD_HOSTNAME=dd101-sre-host
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_SYSTEM_PROBE_ENABLED=true
      - DD_DOCKER_LABELS_AS_TAGS={"my.custom.label.team":"team"}
      - DD_TAGS='env:dd101-sre'
      - DD_APM_NON_LOCAL_TRAFFIC=true
    ports:
      - 127.0.0.1:8126:8126/tcp
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /sys/kernel/debug/:/sys/kernel/debug
    cap_add:
      - SYS_ADMIN
      - SYS_RESOURCE
      - SYS_PTRACE
      - NET_ADMIN
      - NET_BROADCAST
      - NET_RAW
      - IPC_LOCK
      - CHOWN
    security_opt:
      - apparmor:unconfined
  discounts:
    environment:
      - FLASK_APP=discounts.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
      - DD_SERVICE=discounts-service
      - DD_ENV=dd101-sre
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_SERVICE_MAPPING=postgres:database
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/discounts-fixed:2.2.0'
    command:
      [
        sh,
        -c,
        'ddtrace-run flask run --port=5001 --host=0.0.0.0',
      ]
    ports:
      - '5001:5001'
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'discounts-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'discounts'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "discounts-service"}]'
  frontend:
    environment:
      - DD_SERVICE=store-frontend
      - DD_ENV=dd101-sre
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/storefront-fixed:2.2.0'
    command: sh docker-entrypoint.sh
    ports:
      - '3000:3000'
    depends_on:
      - datadog
      - discounts
      - advertisements
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'store-frontend'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'frontend'
      com.datadoghq.ad.logs: '[{"source": "ruby", "service": "store-frontend"}]'
  advertisements:
    environment:
      - FLASK_APP=ads.py
      - FLASK_DEBUG=1
      - POSTGRES_PASSWORD
      - POSTGRES_USER
      - POSTGRES_HOST=db
      - DD_SERVICE=advertisements-service
      - DD_ENV=dd101-sre
      - DD_LOGS_INJECTION=true
      - DD_TRACE_SAMPLE_RATE=1
      - DD_SERVICE_MAPPING=postgres:database
      - DD_PROFILING_ENABLED=true
      - DD_AGENT_HOST=datadog
    image: 'public.ecr.aws/x2b9z2t7/ddtraining/advertisements-fixed:2.2.0'
    command:
      [
        sh,
        -c,
        'ddtrace-run flask run --port=5002 --host=0.0.0.0',
      ]
    ports:
      - '5002:5002'
    depends_on:
      - datadog
      - db
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'advertisements-service'
      com.datadoghq.tags.version: '2.2.0'
      my.custom.label.team: 'advertisements'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "advertisements-service"}]'
  db:
    image: postgres:11-alpine
    restart: always
    environment:
      - POSTGRES_PASSWORD
      - POSTGRES_USER
    ports:
      - '5432:5432'
    labels:
      com.datadoghq.tags.env: 'dd101-sre'
      com.datadoghq.tags.service: 'database'
      com.datadoghq.tags.version: '11.12'
      my.custom.label.team: 'database'
      com.datadoghq.ad.check_names: '["postgres"]'
      com.datadoghq.ad.init_configs: '[{}]'
      com.datadoghq.ad.instances: '[{"host":"%%host%%", "port":5432,"username":"datadog","password":"datadog"}]'
      com.datadoghq.ad.logs: '[{"source": "postgresql", "service": "database"}]'
    volumes:
      - /root/postgres:/var/lib/postgresql/data
      - /root/dd_agent.sql:/docker-entrypoint-initdb.d/dd_agent.sql
  puppeteer:
    image: buildkite/puppeteer:10.0.0
    volumes:
      - /root/puppeteer-mobile.js:/puppeteer.js
      - /root/puppeteer.sh:/puppeteer.sh
    environment:
      - STOREDOG_URL
      - PUPPETEER_TIMEOUT
    depends_on:
      - frontend
    command: bash puppeteer.sh

```

The `cap_add` and `security_opt` sections are required because NPM relies on eBPF, a high-performance, kernel-level interface to a Linux system's data link layer that requires heightened privileges to access.

### Observe the network

#### Network Performance Page

You may see flows where the source and destination are N/A. This represents traffic where the source or destination endpoint cannot be resolved. This happens when:

The host or container source or destination IPs are not tagged with the source or destination tags used for traffic aggregation.
The endpoint is outside of your private network, and accordingly is not tagged by the Agent.
The endpoint is a firewall, service mesh or other entity where an Agent cannot be installed.

#### Network Map

Under the search bar, change the View to service.

Click Filter traffic and toggle the Show N/A (Untagged traffic) off to hide untagged traffic.

To limit the map to only Storedog services, turn off Show cloud service traffic and Show external traffic, too.

### Diagnose latency

Retransmits represent detected failed TCP packets that are retransmitted to ensure delivery, measured in the count of retransmits from the source. You can hover over the bars of this graph to see the number of retransmits and the flows in which they occurred.

Latency is the time between a TCP frame being sent and acknowledged. Here too, you can hover over the points of the graph to see the round-trip time values and the flows in which they occurred.




# introduction to monitoring kubernetes (the cluster is installed)

## Adding the datadog agent to kubernetes

### installing the agent

kubectl create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrole.yaml"

kubectl create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/serviceaccount.yaml"

kubectl create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrolebinding.yaml"

kubectl apply -f k8s-yaml-files/datadog-agent.yaml

kubectl get daemonset

### adding an integration

annotations:
  ad.datadoghq.com/postgres.check_names: '["postgres"]'
  ad.datadoghq.com/postgres.init_configs: '[{}]'
  ad.datadoghq.com/postgres.instances: '[{"host": "%%host%%", "port": "%%port%%","username": "datadog","password": "datadog" }]'

kubectl apply -f k8s-yaml-files/postgres-deploy.yaml

kubectl get pods

### troubleshooting

kubectl get secret/datadog-api -o json

kubectl get secret/datadog-api -o json | jq .data.token | base64 -d -i

kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep datadog

kubectl exec $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep datadog | head -n 1) -- agent status

kubectl apply -f k8s-yaml-files/postgres-deploy.yaml

## Importance of tags

kubectl get pods --no-headers | awk {'print $3'}| datamash -s -g 1 count 1

kubectl get pods

The easiest way to define tags for Datadog on Kubernetes is to use metadata > annotations:

annotations:
  ad.datadoghq.com/tags: '{"key": "value"}'

kubectl apply -f couplemore.yaml

contenido de couplemore:

apiVersion: v1
kind: Pod
metadata:
  name: my-podnew
  annotations:
    ad.datadoghq.com/tags: '{"environment": "qa", "office": "boston", "team": "community", "role": "db", "color": "yellow", "owner":"training"}'
spec:
  containers:
    - name: my-container
      image: ubuntu
      imagePullPolicy: IfNotPresent
      command: ["/bin/bash", "-ec", "sleep infinity"] 
---
apiVersion: v1
kind: Pod
metadata:
  name: my-podnew2
  annotations:
    ad.datadoghq.com/tags: '{"environment": "qa", "office": "boston", "team": "community", "role": "db", "color": "yellow", "owner":"community"}'
spec:
  containers:
    - name: my-container
      image: ubuntu
      imagePullPolicy: IfNotPresent
      command: ["/bin/bash", "-ec", "sleep infinity"] 

## Working with logs on kubernetes

kubectl exec $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep datadog) -- agent status

==========
Logs Agent
==========

    Logs Agent is not running


uncomment in the datadog-agent.yaml file

spec:
  container:
            env:
            # - name: DD_LOGS_ENABLED
            #   value: 'true'
            # - name: DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL
            #   value: 'true'
  volumeMounts:
 # - name: pointerdir
 #   mountPath: /opt/datadog-agent/run
 #   mountPropagation: None
  volumes:
 # - hostPath:
 #     path: /var/lib/datadog-agent/logs
 #   name: pointerdir

complete datadog-agent.yaml:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
  namespace: default
  labels: {}
spec:
  selector:
    matchLabels:
      app: datadog-agent
  template:
    metadata:
      labels:
        app: datadog-agent
      name: datadog-agent
      annotations: {}
    spec:
      containers:
        - image: datadog/agent:7.31.1
          imagePullPolicy: IfNotPresent
          name: datadog-agent
          ports:
            - containerPort: 8125
              hostPort: 8125
              name: dogstatsdport
              protocol: UDP
            - containerPort: 8126
              hostPort: 8126
              name: traceport
              protocol: TCP
          env:
            - name: DD_API_KEY
              valueFrom:
                secretKeyRef:
                  name: 'datadog-api'
                  key: token
            - name: DD_KUBERNETES_KUBELET_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: KUBERNETES
              value: 'yes'
            - name: DD_LOG_LEVEL
              value: 'INFO'
            - name: DD_DOGSTATSD_PORT
              value: '8125'
            - name: DD_DOGSTATSD_NON_LOCAL_TRAFFIC
              value: 'true'
            - name: DD_LEADER_ELECTION
              value: 'true'
            - name: DD_COLLECT_KUBERNETES_EVENTS
              value: 'true'
            - name: DD_LOGS_ENABLED
              value: 'true'
            - name: DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL
              value: 'true'
            - name: DD_LOGS_CONFIG_K8S_CONTAINER_USE_FILE
              value: 'true'
            - name: DD_LOGS_CONFIG_AUTO_MULTI_LINE_DETECTION
              value: 'false'
            - name: DD_HEALTH_PORT
              value: '5555'
            - name: DD_DOGSTATSD_SOCKET
              value: '/var/run/datadog/dsd.socket'
            - name: DD_EXPVAR_PORT
              value: '6000'
          volumeMounts:
            - name: logdatadog
              mountPath: /var/log/datadog
            - name: tmpdir
              mountPath: /tmp
              readOnly: false
            - name: config
              mountPath: /etc/datadog-agent
            - name: runtimesocketdir
              mountPath: /host/var/run
              mountPropagation: None
              readOnly: true
            - name: dsdsocket
              mountPath: /var/run/datadog
            - name: procdir
              mountPath: /host/proc
              mountPropagation: None
              readOnly: true
            - name: cgroups
              mountPath: /host/sys/fs/cgroup
              mountPropagation: None
              readOnly: true
            - name: pointerdir
              mountPath: /opt/datadog-agent/run
              mountPropagation: None
            - name: logpodpath
              mountPath: /var/log/pods
              mountPropagation: None
              readOnly: true
            - name: logscontainerspath
              mountPath: /var/log/containers
              mountPropagation: None
              readOnly: true
            - name: logdockercontainerpath
              mountPath: /var/lib/docker/containers
              mountPropagation: None
              readOnly: true
          livenessProbe:
            failureThreshold: 6
            httpGet:
              path: /live
              port: 5555
              scheme: HTTP
            initialDelaySeconds: 15
            periodSeconds: 15
            successThreshold: 1
            timeoutSeconds: 5
          readinessProbe:
            failureThreshold: 6
            httpGet:
              path: /ready
              port: 5555
              scheme: HTTP
            initialDelaySeconds: 15
            periodSeconds: 15
            successThreshold: 1
            timeoutSeconds: 5
      initContainers:
        - name: init-volume
          image: datadog/agent:7.31.1
          imagePullPolicy: IfNotPresent
          command: ['bash', '-c']
          args:
            - cp -r /etc/datadog-agent /opt
          volumeMounts:
            - name: config
              mountPath: /opt/datadog-agent
          resources: {}
        - name: init-config
          image: datadog/agent:7.31.1
          imagePullPolicy: IfNotPresent
          command: ['bash', '-c']
          args:
            - for script in $(find /etc/cont-init.d/ -type f -name '*.sh' | sort) ; do bash $script ; done
          volumeMounts:
            - name: logdatadog
              mountPath: /var/log/datadog
            - name: config
              mountPath: /etc/datadog-agent
            - name: procdir
              mountPath: /host/proc
              mountPropagation: None
              readOnly: true
            - name: runtimesocketdir
              mountPath: /host/var/run
              mountPropagation: None
              readOnly: true
          env:
            # Needs to be removed when Agent N-2 is built with Golang 1.17
            - name: GODEBUG
              value: x509ignoreCN=0
            - name: DD_API_KEY
              valueFrom:
                secretKeyRef:
                  name: 'datadog-api'
                  key: token
            - name: DD_KUBERNETES_KUBELET_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: KUBERNETES
              value: 'yes'
            - name: DD_LEADER_ELECTION
              value: 'true'
          resources: {}
      volumes:
        - name: installinfo
          configMap:
            name: datadog-installinfo
        - name: config
          emptyDir: {}
        - name: logdatadog
          emptyDir: {}
        - name: tmpdir
          emptyDir: {}
        - hostPath:
            path: /proc
          name: procdir
        - hostPath:
            path: /sys/fs/cgroup
          name: cgroups
        - hostPath:
            path: /var/run/datadog/
            type: DirectoryOrCreate
          name: dsdsocket
        - hostPath:
            path: /var/run/datadog/
            type: DirectoryOrCreate
          name: apmsocket
        - name: s6-run
          emptyDir: {}
        - hostPath:
            path: /var/lib/datadog-agent/logs
          name: pointerdir
        - hostPath:
            path: /var/log/pods
          name: logpodpath
        - hostPath:
            path: /var/log/containers
          name: logscontainerspath
        - hostPath:
            path: /var/lib/docker/containers
          name: logdockercontainerpath
        - hostPath:
            path: /var/run
          name: runtimesocketdir
      tolerations:
      affinity: {}
      serviceAccountName: 'datadog-agent'
      nodeSelector:
        kubernetes.io/os: linux
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 10%
    type: RollingUpdate

```

kubectl apply -f k8s-yaml-files/datadog-agent.yaml

kubectl exec $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep datadog) -- agent status

## APM on kubernetes

in the datadog-agent.yaml

 # - name: DD_APM_ENABLED
 #   value: "true"
 # - name: DD_APM_NON_LOCAL_TRAFFIC
 #   value: "true"

(just changing this the traces appearing)

kubectl apply -f k8s-yaml-files/datadog-agent.yaml

uncomment this lines

 # - name: DD_LOGS_INJECTION
 #   value: 'true'
 # - name: DATADOG_SERVICE_NAME
 #   value: 'frontend-service'
 # - name: DD_TRACE_ANALYTICS_ENABLED
 #   value: 'true'

kubectl apply -f k8s-yaml-files/frontend-service.yaml

uncomment this lines

 # - name: DD_LOGS_INJECTION
 #   value: 'true'
 # - name: DATADOG_SERVICE_NAME
 #   value: 'users-api'
 # - name: DD_TRACE_ANALYTICS_ENABLED
 #   value: 'true'

kubectl apply -f k8s-yaml-files/node-api.yaml

uncomment this lines

 # - name: DD_LOGS_INJECTION
 #   value: 'true'
 # - name: DATADOG_SERVICE_NAME
 #   value: 'pumps-service'
 # - name: DD_TRACE_ANALYTICS_ENABLED
 #   value: 'true'

kubectl apply -f k8s-yaml-files/pumps-service.yaml

uncomment this lines

 # - name: DD_LOGS_INJECTION
 #   value: 'true'
 # - name: DATADOG_SERVICE_NAME
 #   value: 'sensors-api'
 # - name: DD_TRACE_ANALYTICS_ENABLED
 #   value: 'true'

kubectl apply -f k8s-yaml-files/sensors-api.yaml

original yaml files

- frontend-service.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-service
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: frontend-service
  template:
    metadata:
      labels:
        app: frontend-service
    spec:
      containers:
        - name: frontend-service
          image: burningion/k8s-distributed-tracing-frontend:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5005
              hostPort: 5005
              name: frontendport
              protocol: TCP
          env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DOGSTATSD_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            # - name: DD_LOGS_INJECTION
            #   value: 'true'
            # - name: DD_TRACE_ANALYTICS_ENABLED
            #   value: 'true'
            # - name: DATADOG_SERVICE_NAME
            #   value: 'frontend-service'
            - name: FLASK_APP
              value: 'api'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5005'
            - name: DATADOG_PATCH_MODULES
              value: 'requests:true'
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend-service
  ports:
    - name: http
      protocol: TCP
      port: 5005
      nodePort: 30001
  type: NodePort

```

node-api.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: node-api
  template:
    metadata:
      labels:
        app: node-api
    spec:
      containers:
        - name: node-api
          image: burningion/k8s-distributed-tracing-users:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5004
              name: node-port
              hostPort: 5004
          env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DOGSTATSD_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
          # - name: DD_SERVICE_NAME
          #   value: 'users-api'
          # - name: DD_LOGS_INJECTION
          #   value: 'true'
          # - name: DD_TRACE_ANALYTICS_ENABLED
          #   value: 'true'
---
apiVersion: v1
kind: Service
metadata:
  name: node-api
spec:
  selector:
    app: node-api
  ports:
    - name: http
      protocol: TCP
      port: 5004
  type: NodePort

```

pumps-service.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pumps-service
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: pumps-service
  template:
    metadata:
      labels:
        app: pumps-service
    spec:
      containers:
        - name: pumps-service
          image: burningion/k8s-distributed-tracing-pumps:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5001
          env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DOGSTATSD_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            # - name: DATADOG_SERVICE_NAME
            #   value: 'pumps-service'
            # - name: DD_LOGS_INJECTION
            #   value: 'true'
            # - name: DD_TRACE_ANALYTICS_ENABLED
            #   value: 'true'
            - name: FLASK_APP
              value: 'thing'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5001'
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-user
                  key: token
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-password
                  key: token
---
apiVersion: v1
kind: Service
metadata:
  name: pumps-service
spec:
  selector:
    app: pumps-service
  ports:
    - name: http
      protocol: TCP
      port: 5001
  type: NodePort

```

sensors-api.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sensors-api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: sensors-api
  template:
    metadata:
      labels:
        app: sensors-api
    spec:
      containers:
        - name: sensors-api
          image: burningion/k8s-distributed-tracing-sensors:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5002
          env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DOGSTATSD_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            # - name: DATADOG_SERVICE_NAME
            #   value: 'sensors-api'
            # - name: DD_LOGS_INJECTION
            #   value: 'true'
            # - name: DD_TRACE_ANALYTICS_ENABLED
            #   value: 'true'
            - name: FLASK_APP
              value: 'sensors'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5002'
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-user
                  key: token
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-password
                  key: token
---
apiVersion: v1
kind: Service
metadata:
  name: sensors-api
spec:
  selector:
    app: sensors-api
  ports:
    - name: http
      protocol: TCP
      port: 5002
  type: NodePort

```

## Monitoring kubernetes

When Kubernetes becomes an important part of your infrastructure, it’s crucial to monitor it. We will look at monitoring the applications on top of Kubernetes a bit later, but let’s talk about what you need to pay attention to with the platform itself.

A Kubernetes cluster is made up of two primary node types: control plane nodes and worker nodes. The control plane nodes can include etcd data stores, API servers, and controller managers and schedulers. For each of the components, you are going to need to look at both the system metrics that come from the OS, as well as platform-specific metrics that come through our Prometheus integration.

For system metrics, you need to keep an eye on system load, disk latency, network IO, and memory used. Each component relies on these resources a different amount. For instance, disk latency is incredibly important on etcd, with an SSD providing a huge boost. CPU and memory load is going to be critical on the API Server since it's your connection to etcd and everything else. Of course the exact metrics to watch is largely going to depend on how you architect your Kubernetes environment, but there are some general tips to keep in mind.

Login to Datadog. In the main menu, navigate to the Dashboards List by hovering your cursor over Dashboards and selecting Dashboards > Dashboard List.

Find the Kubernetes - Overview dashboard. Is there anything missing from the dashboard that we have talked about so far?

Is there anything you would do to tweak the dashboard for your needs? Is this better as a screenboard or a timeboard?




The main database that tracks everything in the cluster is etcd and it's made up of multiple nodes. Although there is a leader, writes are only committed when a quorum of nodes agrees to the write proposal. So you need to ensure that there is always a single leader. Lack of a leader or too many leaders at any one time will be an issue. And you want to make sure you have enough nodes at any time to reach a quorum, but not so many that the network becomes saturated. You also have to make sure your data is sized properly for your nodes. If network IO increases it could be a sign that a new leader is being elected. And while there can be multiple proposals pending at any time, there should not be any failed proposals.

The etcd database defaults to a maximum size of 2GB, though you can configure that to be up to 8GB. Whatever size you choose, you should monitor the size to ensure it stays under that limit. This is a great metric to employ a forecast on, letting you know that it is likely that you will hit the max soon. Another great feature to take a look at is the ability to create a graph based on log events that match a certain criteria. You could watch for the phrase “took too long" which indicates a slow request. Count how many of those happen in any time period and you have an interesting graph that can report when you are having too many slow requests.

The API Server is cpu and memory intensive so keeping an eye on the relevant system metrics is important. The API Server is your interface to etcd and the other components. Its a big server but it's hard to load balance as you normally would like to.

Review the following materials, and build some dashboards that allow you to monitor the Kubernetes platform in interesting ways:

EKS Cluster Metrics from the Datadog Blog

Monitoring Kubernetes Metrics from the Datadog Blog

## Monitoring your applications on kubernetes

- https://github.com/DataDog/integrations-core/tree/master/postgres/datadog_checks/postgres/data
- https://github.com/DataDog/integrations-core/tree/master/redisdb/datadog_checks/redisdb/data

Both of these pages are folders in our integrations-core repository on Github. This is where you can find all of the integrations that we wrote and that we support. Notice that the redis folder includes and auto_conf.yaml file and the postgres folder does not. Any integration that includes an auto_conf.yaml file is one that we will attempt to integrate with automatically.

In the redisdb/data folder, click on the auto_conf.yaml file.

This is the configuration for the Redis integration. The first line says that we will look for any container named redis and apply the settings below. Redis is usually setup to use port 6379 but the host name is unknown until runtime. %%host%% will be replaced at runtime with the correct value.

Go back to the redisdb/data folder and click on conf.yaml.example.

This is the complete YAML that you can use in your configuration. If the other options are important for you, you can override them using annotations. But rather than override redis, we will just setup postgres.

uncomment this lines in the postgres-deploy.yaml

      # annotations:
      #   ad.datadoghq.com/postgres.check_names: '["postgres"]'
      #   ad.datadoghq.com/postgres.init_configs: '[{}]'
      #   ad.datadoghq.com/postgres.instances: '[{"host": "%%host%%", "port": "%%port%%","username": "datadog","password": "postgres" }]'


kubectl apply -f k8s-yaml-files/postgres-deploy.yaml

review the next file (corresponding to a conf.d/)

- https://github.com/DataDog/integrations-core/blob/master/postgres/datadog_checks/postgres/data/conf.yaml.example

The values in that conf.d/ file will be passed as variables to our postgres-deploy.yaml.

For example having the next postgres.yaml content:

init_config:
  instances:
   - host: localhost
     port: 5432
     username: datadog
     password: <UNIQUEPASSWORD>

Your application yaml would use that variables in the annotations

annotations:
  ad.datadoghq.com/postgres.check_names: '["postgres"]'
  ad.datadoghq.com/postgres.init_configs: '[{}]'
  ad.datadoghq.com/postgres.instances: '[{"host": "%%host%%", "port": "%%port%%","username": "datadog","password": "postgres" }]'




