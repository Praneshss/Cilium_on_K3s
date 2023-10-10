sudo mount bpffs -t bpf /sys/fs/bpf

export MASTER_IP=$(ip a |grep global | grep -v '10.0.2.15' | awk '{print $2}' | cut -f1 -d '/' | grep '^192')

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none \
 --node-ip=${MASTER_IP} --node-external-ip=${MASTER_IP} --cluster-cidr=192.168.0.0/16 \
--bind-address=${MASTER_IP} no-deploy=servicelb no-deploy=traefik" sh -
systemctl status k3s
echo $MASTER_IP > /vagrant/master-ip
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo sed -i -e "s/127.0.0.1/${MASTER_IP}/g" /vagrant/k3s.yaml

sudo wget — no-check-certificate https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
sudo tar -zxvf helm-v3.12.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

sudo helm repo add cilium https://helm.cilium.io/

sudo sh -c 'echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment'

sudo helm install cilium cilium/cilium --version=1.14.2     --set global.tag="v1.14.2" --set global.containerRuntime.integration="containerd"     --set global.containerRuntime.socketPath="/var/run/k3s/containerd/containerd.sock"     --set global.kubeProxyReplacement="strict" --namespace kube-system

sudo kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod

sleep 0.5

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} 


helm upgrade cilium cilium/cilium --version 1.14.2 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
   
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}

#sleep 0.5
sudo cilium status --wait
