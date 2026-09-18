# Nginx Demo Container Image

Examples for using the images in Kubernetes.

## Basic Kubernetes Deployment

Example Kubernetes manifests are available in `deploy/deployment-v*.yaml`.

Deploy the latest version to your Kubernetes cluster with:

```sh
# Create 3 Deployments with different custom attribites
kubectl apply -f \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/deployment-v3.yaml
```

*Note that the `startupProbe` timing is intentionally longer than necessary to allow us to observe the transitions.*

## Accessing The Service

### Service

Create a service to expose the application. Options include:

```sh
# Create ClusterIP Service
kubectl apply -f \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/service-clusterip.yaml
# Create NodePort Service
kubectl apply -f \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/service-nodeport.yaml
# Create LoadBalancer Service
kubectl apply -f \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/service-loadbalancer.yaml
```

**Note:**

> You could now access the service by port fowarding it to your device, with a command like this:
> `kubectl port-forward service/nginx-demo 9090:8080`.
>
> This will prove that the service is running, but not provide any Service-level load balancing,
> as `kubectl port-forward` establishes a direct point-to-point tunnel to one single target pod.

### Ingress / OpenShift Route

Depending on youe Kubernetes cluster, you can expose the service outside the cluster, with one of:

```sh
# Create Ingress (substitute `${YOUR_DOMAIN}`)
curl --silent \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/ingress.yaml \
  | sed -e "s/ host: .*/ host: nginx-demo.${YOUR_DOMAIN}/" > /tmp/ingress.yaml
# Review the /tmp/ingress.yaml file to match your cluster (check `ingressClassName` etc), then:
kubectl apply -f /tmp/ingress.yaml

# Alternate: create OpenShift Route
kubectl apply -f \
  https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/openshift-route.yaml
```

### Minikube

*Doc: [Accessing apps](https://minikube.sigs.k8s.io/docs/handbook/accessing/)*

In Minikube, if you created a LoadBalancer Service, you can access it by running:

```sh
minikube tunnel
```

In a different terminal, run this to get the external IP where you can access it:

```shell
$ kubectl get svc -l app.kubernetes.io/name=nginx-demo
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
nginx-demo   LoadBalancer   10.104.3.199   10.104.3.199   8080:31066/TCP   11h
```

In this example, the service should not be accessible at `http://10.104.3.199:8080/`.

### Kind

*Doc: [Quick Start](https://kind.sigs.k8s.io/docs/user/configuration/)*

In kind (Kubernetes in Docker), you can map extra ports from the nodes to the host machine.

To do this, create the cluster with:

```sh
wget https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/kind-config.yaml
wget https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/service-kind.yaml
kind create cluster --config kind-config.yaml
kubectl apply -f service-kind.yaml
```

The service should now be accessible at `http://127.0.0.1:30080/`.

## Kubernetes Rolling Update Demo

To demonstrate [Kubernetes rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/), try these steps:

```sh
# Deploy the version 1 image:
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/deployment-v1.yaml
# Port forward the service to your device so you can access it locally
# (replace port 9090 to suite your needs):
kubectl port-forward service/nginx-demo 9090:8080
# Connect to the service with a web browser (http://0.0.0.0:9090), and reload
# a few times to see the load balancing between the 3 deployments.
#
# Change the `$COLOR` of 2 of the deployments:
kubectl patch deployment nginx-demo-2 -p '{"spec":{"template":{"spec":{
"containers":[{"name":"nginx-demo","env":[{"name":"COLOR","value":"#1F63E0"}]}]
}}}}'

kubectl patch deployment nginx-demo-3 -p '{"spec":{"template":{"spec":{
"containers":[{"name":"nginx-demo","env":[{"name":"COLOR","value":"#3BC639"}]}]
}}}}'
# Watch the rollout happen (Ctrl-C to stop),
# while also reloading the web page to see the effects:
watch -n 1 kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo

# Upgrade to the version 2 image:
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/deployment-v2.yaml
# Watch the rollout happen (Ctrl-C to stop),
# while also reloading the web page to see the effects:
watch -n 1 kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo

# Upgrade to the version 3 image:
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/deployment-v3.yaml
# Watch the rollout happen (Ctrl-C to stop),
# while also reloading the web page to see the effects:
watch -n 1 kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo
```

## Failed Container Restart

To test the liveness probe & automatic restart of a pod, remove the
`healthz.json` file so that the probe fails:

```sh
kubectl get pods -l app.kubernetes.io/name=nginx-demo
kubectl exec <podname> -- rm /usr/share/nginx/html/healthz.json
watch -n 1 kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo
```
