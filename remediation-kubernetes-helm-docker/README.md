# simpleapp
Simple Hello World App Written in GoLang.  Including Kubernetes deployment YAML file and Helm Chart.


1. Containers run with AllowPrivilegeEscalation

Description

The AllowPrivilegeEscalation Pod Security Policy controls whether or not a user is allowed to set the security context of a container to True. Setting it to False ensures that no child process of a container can gain more privileges than its parent.

We recommend you to set AllowPrivilegeEscalation to False, to ensure RunAsUser commands cannot bypass their existing sets of permissions.

Fix - Buildtime

Kubernetes

Resource: Container
Argument: allowPrivilegeEscalation (Optional)
If false, the pod can not request to allow privilege escalation. Default to true.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-dpl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend-container
          image: lmnzr/simplefrontend:latest
          env:
            - name: BACKEND_URL
              value: "http://backend-svc:8080"
          resources:
            limits:
              memory: "128Mi"
              cpu: "500m"
          ports:
            - containerPort: 80
          securityContext:
               allowPrivilegeEscalation: false
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  type: NodePort
  ports:
    - port: 80
      protocol: TCP
  selector:
    app: frontend

```

apiVersion: v1
kind: Service
metadata:
  name: <my-nodeport-service>
  labels:
    <my-label-key>: <my-label-value>
spec:
  selector:
    <my-selector-key>: <my-selector-value>
  type: NodePort
  ports:
   - port: <8081>
     # nodePort: <31514>