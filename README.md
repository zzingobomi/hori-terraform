# Hori Terraform

### Prerequisite

1. asw-cli: 2.15.1

2. terraform: 1.5.4

3. kubectl 설치
  - https://kubernetes.io/ko/docs/tasks/tools/

4. kubectl 단축키 셋팅 (Optional)
  - Mac .zshrc 파일 수정
    ```
    ...
    alias k=kubectl
    [[$commands[kubectl]]] && source <(kubectl completion zsh)
    ```
  - Linux .zshrc 파일 수정
    ```
    ...
    alias k=kubectl
    source <(kubectl completion zsh)
    ```

### Usage

1. EKS 구축
```sh
$ cd eks
$ terraform init
$ terraform apply
```

2. k8s configure 셋팅
```sh
  $ aws eks update-kubeconfig --region ap-northeast-2 --name hori
  $ kubectl cluster-info
  $ kubectl get pods --all-namespaces
```

3. mysql database 접속
```sh
kubectl port-forward -n mysql-cluster svc/mysql-cluster 33060:3306
```
- 포트번호 임의 설정 가능
- mysql client 접속 프로그램으로 접속 (127.0.0.1:33060)
- api 데이터베이스 만들기

4. Argo CD 비밀번호 확인
```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

5. Grafana 비밀번호 확인
```sh
kubectl get secrets kube-prometheus-stack-grafana --namespace kube-prometheus-stack -o jsonpath="{.data.admin-password}" | base64 -d
```

6. kube-ops-view 로컬 접속 (Optional)
```sh
kubectl port-forward -n kube-system svc/kube-ops-view 18080:8080
```
- 포트번호 임의 설정 가능

7. Application 배포
```sh
$ cd application
$ terraform init
$ terraform apply
```


### TODO
- dev, prod workspace 나누기
- 인증서 테스트 후 github helm 에서 arn 지우기
- api database 자동 생성 가능? 
- application 로드밸런서는 terraform 에서 만든게 아니라 destroy 할때 제대로 못지우는듯
- HPA 적용
- Karpenter 적용

