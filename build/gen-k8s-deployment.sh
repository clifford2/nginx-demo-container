#!/usr/bin/env bash
#
# Generate K8s Deployment resource YAML
# This version handles v 1-3 images, and accepts version/message pairs as command line arguments
#
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

startupdelay=2

usage() {
	echo "Usage: $0 [majorversion message] ..."
	exit 1
}

if [ $# -lt 2 ]
then
	usage
fi

declare -a versions
declare -a messages
while [ $# -gt 0 ]
do
	if [ $# -lt 2 ]
	then
		echo "Error: odd number of arguments"
		usage
	fi
	versions+=("$1")
	shift
	messages+=("$1")
	shift
done

cat <<- HEADER
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0
HEADER

for idx in "${!versions[@]}"
do
	major="${versions[$idx]}"
	ver=$(bash ../build/getver patch $major)
	(( msgidx = $idx + 1 ))
	echo "ver $ver idx $msgidx message [${messages[$idx]}]" >&2

	if [ ${major} -eq 1 ]
	then
		envvarname='COLOR'
		labelname='coloridx'
	elif [ ${major} -eq 2 ]
	then
		envvarname='MESSAGE'
		labelname='msgidx'
	elif [ ${major} -eq 3 ]
	then
		envvarname='MESSAGE'
		labelname='msgidx'
	else
		echo "Error: Invalid major version '${major}'"
		exit 1
	fi

	cat <<- DEPLOYMENTYAML

---
# Version ${major} deployment ${msgidx}
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
    ${labelname}: "${msgidx}"
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
        ${labelname}: "${msgidx}"
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
if [ -n "${messages[$idx]}" ]
then
	cat <<- ENVYAML
          env:
            - name: "${envvarname}"
              value: "${messages[$idx]}"
ENVYAML
fi
	(( startupdelay = startupdelay + 5 ))
done
