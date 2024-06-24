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

1. Argo CD 비밀번호 

- kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

2. Grafana 비밀번호

- kubectl get secrets kube-prometheus-stack-grafana --namespace kube-prometheus-stack -o jsonpath="{.data.admin-password}" | base64 -d

3. kube-ops-view 로컬 접속

- kubectl port-forward -n kube-system svc/kube-ops-view 18080:8080 (포트번호 임의 설정 가능)

4. mysql database 접속

- kubectl port-forward -n mysql-cluster svc/mysql-cluster 33060:3306 (포트번호 임의 설정 가능)
- mysql client 접속 프로그램으로 접속 (127.0.0.1:33060)
- api 데이터베이스 만들기

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

- https 적용

- 어떻게 단계를 나눠서 실행할 것인가? 
  1. eks 를 구축하는 단계
  2. application 을 argocd 에 배포하는 단계

- loki 설치
- dev, prod workspace 나누기
- post apply 자동화 더 자동화 가능?

### Prerequisites

asw-cli: 2.15.1
terraform: 1.5.4
