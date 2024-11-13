minikube kubectl -- apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

minikube kubectl -- patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

minikube kubectl -- rollout restart deployment metrics-server -n kube-system

minikube kubectl -- apply -f app-deploy.yml

minikube kubectl -- get all
