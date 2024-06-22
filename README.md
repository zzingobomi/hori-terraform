# Hori Terraform

### 개발환경 셋팅

- kubectl 설치
  - https://kubernetes.io/ko/docs/tasks/tools/
- k8s configure 셋팅
  - aws eks update-kubeconfig --region ap-northeast-2 --name hori
  - kubectl cluster-info
  - kubectl get pods --all-namespaces
- kubectl 단축키 셋팅
  - Mac .zshrc 파일 수정
    - alias k=kubectl
    - [[$commands[kubectl]]] && source <(kubectl completion zsh)
  - Linux .zshrc 파일 수정
    - alias k=kubectl
    - source <(kubectl completion zsh)

### Post apply

- Argo CD 외부 노출
  - kubectl patch svc argo-cd-argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'
  - kubectl annotate service argo-cd-argocd-server -n argocd "external-dns.alpha.kubernetes.io/hostname=argocd.practice-zzingo.net"
  - kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
- Grafana 외부 노출
  - kubectl patch svc kube-prometheus-stack-grafana -n kube-prometheus-stack -p '{"spec":{"type":"LoadBalancer"}}'
  - kubectl annotate service kube-prometheus-stack-grafana -n kube-prometheus-stack "external-dns.alpha.kubernetes.io/hostname=grafana.practice-zzingo.net"
  - kubectl get secrets kube-prometheus-stack-grafana --namespace kube-prometheus-stack -o jsonpath="{.data.admin-password}" | base64 -d
- kube-ops-view 외부 노출
  - kubectl patch svc kube-ops-view -n kube-system -p '{"spec":{"type":"LoadBalancer"}}'
  - kubectl annotate service kube-ops-view -n kube-system "external-dns.alpha.kubernetes.io/hostname=kubeopsview.practice-zzingo.net"
  - http://kubeopsview.practice-zzingo.net:8080/

### TODO

- argocd-image-updator 설치 - annotations 확인
- hori 앱 설치 (argo 통해서?) - 블루그린 배포
- loki 설치
- post apply 자동화..

### Prerequisites

asw-cli: 2.15.1
terraform: 1.5.4
