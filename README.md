# Hori Terraform

- kubectl 설치
  - https://kubernetes.io/ko/docs/tasks/tools/
- k8s configure 셋팅
  - aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
  - kubectl cluster-info
  - kubectl get pods --all-namespaces
- kubectl 단축키 셋팅
  - Mac .zshrc 파일 수정
    - alias k=kubectl
    - [[$commands[kubectl]]] && source <(kubectl completion zsh)

### Prerequisites

asw-cli: 2.15.1
terraform: 1.5.4
