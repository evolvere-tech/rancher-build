# Install Rancher in Azure

Management machine running these scripts needs terraform, ansible, rke, kubectl and helm installed.

### Create ssh keys

```bash
ssh-keygen
```

### Build VM(s) with terraform

```
cd terraform
```
Edit rancher.tf file and set ```public_key``` to location of generated public key.

```bash
terraform verify
terraform plan --out rancher-plan
terraform apply "rancher-plan"
```

### Run Ansible playbook to install docker on VM(s)

```bash
cd ansible
```
Edit ```hosts``` file and update hostnames and IP addresses.

```bash
ansible-playbook -i hosts docker_play.yml -vvv
```

### Build RKE cluster

```bash
cd rke
```
Edit ```cluster.yml``` file and update host IP adresses and roles.

```bash
rke up --config ./cluster.yml
export KUBECONFIG=$(pwd)/kube_config_cluster.yml
kubectl get nodes
kubectl get pods —all-namespaces
```

### Install Rancher
```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
helm repo update

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher-test.evolvere-tech.com \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=info@evolvere-tech.co.uk

kubectl -n cattle-system rollout status deploy/rancher
```
