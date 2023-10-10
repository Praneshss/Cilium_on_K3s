# cilium-k3s-demo-updated
Demonstrates setting up of Cilium on K3s using Vagrant and Virtualbox
Kindly Refer the document "setup.pdf" for detailed step-by-setp details of cilium installation on K3s in PDF. 

# Setting up Cilium on K3s using Vagrant and Virtualbox

## Introduction
In this guide, we will outline the procedure for configuring a Cilium setup on K3s using Vagrant and Virtualbox. The setup consists of a host machine, a master virtual machine (VM), and one or more agent VMs. We'll walk you through the installation and configuration process on a host machine running Ubuntu 20.04.

## Host Machine Setup
Ensure that you have Virtualbox and Vagrant installed on your host machine by running the following commands:

```bash
sudo apt-get install virtualbox
sudo apt install vagrant
vagrant plugin install vagrant-vbguest
```

Next, clone the Cilium-K3s-Demo repository:

```bash
git clone https://github.com/Praneshss/Cilium_on_K3s.git
cd Cilium_on_K3s/Cilium_K3s_Updated/
```


## Vagrant Configuration
### Vagrantfile
The Vagrantfile provided defines the VM setup. By default, one K3s agent is configured, but you can specify the number of agents using the `K3S_AGENTS` environment variable.

```ruby
# Vagrant configuration
number_of_agents = (ENV['K3S_AGENTS'] || "1").to_i
box_name = (ENV['VAGRANT_BOX'] || "ubuntu/focal64")

Vagrant.configure("2") do |config|
  # ... (Vagrant VM configuration) 
end
```

### Network Configuration
To avoid potential errors with VirtualBox host-only networks, modify the `/etc/networks.conf` file:

```bash
sudo mkdir /etc/vbox
sudo nano /etc/vbox/networks.conf
```

In `/etc/vbox/networks.conf`, add the following networks:

```bash
* 10.0.0.0/8 192.168.0.0/16
* 2001::/64
```

Refer to [StackOverflow](https://stackoverflow.com/questions/69722254/vagrant-up-failing-for-virtualbox-provider-with-e-accessdenied-on-host-only-netw) for more details.

## Running the Setup

Run the Vagrant script to set up the VMs:

```bash
vagrant up
```

If the setup completes without errors, the initial configuration is successful.

## VM Network Checks

If shell provisioning fails for the master and agent nodes, verify the network connections manually:

```bash
vagrant ssh master
vagrant ssh agent1
```

From the master VM, ping the following IPs:

```bash
ping 192.168.80.101
ping 10.161.5.192
```

From agent1 VM, ping the following IPs: 

```bash
ping 192.168.80.10
ping 10.161.5.192
```

## Master VM Configuration
### Master VM Setup

Run the following commands within the master VM:

```bash
sudo mount bpffs -t bpf /sys/fs/bpf
export MASTER_IP=$(ip a |grep global | grep -v '10.0.2.15' | awk '{print $2}' | cut -f1 -d '/')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --node-ip=${MASTER_IP} --node-external-ip=${MASTER_IP} --cluster-cidr=192.168.0.0/16 --bind-address=${MASTER_IP} no-deploy=servicelb no-deploy=traefik" sh -
systemctl status k3s
echo $MASTER_IP > /vagrant/master-ip
# ... (Install Helm and Cilium)
```

### Install Helm and Cilium

Install Helm, the Kubernetes package manager, as follows:

```bash
helm upgrade cilium cilium/cilium --version 1.14.2 --namespace kube-system --reuse-values --set hubble.relay.enabled=true --set hubble.ui.enabled=true
```

Verify the Helm Installation

```bash
kubectl get pods -n kube-system -o wide
```

Add the line in /etc/environment file

```bash 
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Install Cilium using Helm:

```bash
sudo helm repo add cilium https://helm.cilium.io/
sudo helm install cilium cilium/cilium --version=1.14.2 --set global.tag="v1.14.2" --set global.containerRuntime.integration="containerd" --set global.containerRuntime.socketPath="/var/run/k3s/containerd/containerd.sock" --set global.kubeProxyReplacement="strict" --namespace kube-system
```

Verify the Cilium installation:

```bash
sudo kubectl get pods -n kube-system -o wide
```

### Install Hubble

Upgrade Cilium to enable Hubble:

```bash 
helm upgrade cilium cilium/cilium --version 1.14.2 --namespace kube-system --reuse-values --set hubble.relay.enabled=true --set hubble.ui.enabled=true
```

Verify the Hubble installation:

```bash
kubectl get pods -n kube-system -o wide
```

## Agent VM Configuration

### Agent Installation

Retrieve the server's IP address and node token:

```bash
export K3S_URL=https://192.68.80.10:6443
```

Run the following commands on the agent VM:

```bash
export AGENT_IP=$(ip a |grep global | grep -v '10.0.2.15' | awk '{print $2}' | cut -f1 -d '/')
export MASTER_IP=$(cat /vagrant/master-ip) 
export NODE_TOKEN=$(cat /vagrant/node-token)

sudo mount bpffs -t bpf /sys/fs/bpf


curl -sfL https://get.k3s.io |    \
        K3S_URL="https://${MASTER_IP}:6443" \
        K3S_TOKEN="<node_token>"  \
        K3S_FLANNEL_BACKEND=none  \
        INSTALL_K3S_EXEC="--node-ip=${AGENT_IP} --node-external-ip=${AGENT_IP}" sh -
```

Enable the agent:

```bash
systemctl enable --now k3s-agent
```

Check the agent's status to confirm it's detected by Kubernetes and verify its status

```
sudo kubectl get nodes
```
