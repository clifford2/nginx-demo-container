#!/usr/bin/env bash

# Generate K8s Deployment resource YAML for v2+ images with $MESSAGE

# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

ver=$1
test -z "${ver}" && exit 1
major=$(echo "${ver}" | cut -d. -f1)

startupdelay=2

cat <<- HEADER
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

HEADER

declare -a messages
# messages=('Doc' 'Grumpy' 'Happy' 'Sleepy' 'Bashful' 'Sneezy' 'Dopey')
# messages=('Timon' 'Pumbaa' 'Simba')
if [ ${major} -eq 3 ]
then
	messages+=("Ah, you're an outcast! That's great, so are we! - Timon")
	messages+=("They call me Mr. Pig! - Puumba")
	messages+=("This is my kingdom. If I don't fight for it, who will? - Simba")
else
	messages=('Bashful' 'Sneezy' 'Dopey')
fi

for idx in "${!messages[@]}"
do
	(( msgidx = $idx + 1 ))
	cat <<- DEPLOYMENTYAML
---
# Nginx Demo deployment - ${msgidx}
apiVersion: "apps/v1"
kind: "Deployment"
metadata:
  name: "nginx-demo-${msgidx}"
  labels:
    app.kubernetes.io/name: "nginx-demo"
    app.kubernetes.io/instance: "nginx-demo-${msgidx}"
    app.kubernetes.io/version: "${ver}"
    app.kubernetes.io/component: "website"
    app: "nginx-demo-${msgidx}"
    version: "${ver}"
    msgidx: "${msgidx}"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: "nginx-demo"
      app.kubernetes.io/instance: "nginx-demo-${msgidx}"
  template:
    metadata:
      labels:
        app.kubernetes.io/name: "nginx-demo"
        app.kubernetes.io/instance: "nginx-demo-${msgidx}"
        app.kubernetes.io/version: "${ver}"
        app.kubernetes.io/component: "website"
        app: "nginx-demo-${msgidx}"
        version: "${ver}"
        msgidx: "${msgidx}"
    spec:
      hostNetwork: false
      hostPID: false
      hostIPC: false
      restartPolicy: "Always"
      terminationGracePeriodSeconds: 30
      volumes:
        - name: "nginx-tmp-1"
          emptyDir: {}
        - name: "nginx-tmp-2"
          emptyDir: {}
      containers:
        - name: "nginx-demo"
          image: "ghcr.io/clifford2/nginx-demo:${ver}"
          imagePullPolicy: "IfNotPresent"
          ports:
            - name: "http"
              containerPort: 8080
              protocol: "TCP"
          startupProbe:
            httpGet:
              port: 8080
              path: "/healthz.json"
            failureThreshold: 3
            initialDelaySeconds: ${startupdelay}
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            httpGet:
              port: 8080
              path: "/healthz.json"
            failureThreshold: 2
            initialDelaySeconds: 2
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          livenessProbe:
            httpGet:
              port: 8080
              path: "/healthz.json"
            failureThreshold: 2
            initialDelaySeconds: 2
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          resources:
            requests:
              memory: "16Mi"
            limits:
              memory: "32Mi"
          terminationMessagePath: "/dev/termination-log"
          terminationMessagePolicy: "File"
          volumeMounts:
            - name: "nginx-tmp-1"
              mountPath: "/tmp"
            - name: "nginx-tmp-2"
              mountPath: "/usr/share/nginx/html"
          securityContext:
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            privileged: false
            capabilities:
              drop:
                - "ALL"
            seccompProfile:
              type: "RuntimeDefault"
          env:
            - name: "MESSAGE"
              value: "${messages[$idx]}"
DEPLOYMENTYAML
	(( startupdelay = startupdelay + 5 ))
done
