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

1. Argo CD 외부 노출

- kubectl patch svc argo-cd-argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'
- kubectl annotate service argo-cd-argocd-server -n argocd "external-dns.alpha.kubernetes.io/hostname=argocd.practice-zzingo.net"
- kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

2. Grafana 외부 노출

- kubectl patch svc kube-prometheus-stack-grafana -n kube-prometheus-stack -p '{"spec":{"type":"LoadBalancer"}}'
- kubectl annotate service kube-prometheus-stack-grafana -n kube-prometheus-stack "external-dns.alpha.kubernetes.io/hostname=grafana.practice-zzingo.net"
- kubectl get secrets kube-prometheus-stack-grafana --namespace kube-prometheus-stack -o jsonpath="{.data.admin-password}" | base64 -d

3. kube-ops-view 외부 노출

- kubectl patch svc kube-ops-view -n kube-system -p '{"spec":{"type":"LoadBalancer"}}'
- kubectl annotate service kube-ops-view -n kube-system "external-dns.alpha.kubernetes.io/hostname=kubeopsview.practice-zzingo.net"
- http://kubeopsview.practice-zzingo.net:8080/

4. mysql database 접속

- kubectl run --rm -it myshell --image=container-registry.oracle.com/mysql/community-operator -- mysqlsh
- MySQL> \connect root@mysql-cluster.mysql-cluster.svc.cluster.local
- MySQL> CREATE DATABASE api

5. ArgoCD 어플리케이션 셋팅

6. ArgoCD image updator 셋팅

- argocd-image-updater.argoproj.io/image-list : hori-frontend=zzingo5/hori-frontend,hori-backend=zzingo5/hori-backend

- argocd-image-updater.argoproj.io/hori-frontend.update-strategy : name
- argocd-image-updater.argoproj.io/hori-frontend.allow-tags : regexp:^\d{8}-\d{1,}$
- argocd-image-updater.argoproj.io/hori-frontend.helm.image-name: frontend.image.repository
- argocd-image-updater.argoproj.io/hori-frontend.helm.image-tag : frontend.image.tag

- argocd-image-updater.argoproj.io/hori-backend.update-strategy : name
- argocd-image-updater.argoproj.io/hori-backend.allow-tags : regexp:^\d{8}-\d{1,}$
- argocd-image-updater.argoproj.io/hori-backend.helm.image-name : backend.image.repository
- argocd-image-updater.argoproj.io/hori-backend.helm.image-tag : backend.image.tag

### TODO

- helm chart eks, onpromise 용 만들기 및 경로 변경
- 블루그린 배포
- loki 설치
- post apply 자동화..
- bastion host 설정
  - https://github.com/mysql/mysql-operator?tab=readme-ov-file#using-port-forwarding
  - mysql 을 로컬에서 접속하려면 port-forwad 를 해줘야 하는데 이미 있다고 에러가 나옴
  - 그래서 ssh tunneling 을 통해 dbeaver 로 접속이 불가능한거 같음
  - 해결방안 아직 모름

### Prerequisites

asw-cli: 2.15.1
terraform: 1.5.4
