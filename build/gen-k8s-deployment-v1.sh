#!/usr/bin/env bash

# Generate K8s Deployment resource YAML for v1 images with $COLOR

# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

ver=${1:-$(bash ../build/getver patch 1)}
test -z "${ver}" && exit 1

startupdelay=2

cat <<- HEADER
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

HEADER

declare -a colors
colors=('' 'blue' 'green')
for idx in "${!colors[@]}"
do
	(( msgidx = $idx + 1 ))
	color="${colors[$idx]}"
	colorlabel="${color:-default}"

	cat <<- DEPLOYMENTYAML
---
# Nginx Demo deployment - ${colorlabel}
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
    coloridx: "${msgidx}"
    color: "${colorlabel}"
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
        color: "${colorlabel}"
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
DEPLOYMENTYAML
if [ ! -z "${color}" ]
then
	cat <<- COLORYAML
          env:
            - name: "COLOR"
              value: "${color}"
COLORYAML
fi
	(( startupdelay = startupdelay + 5 ))
done
