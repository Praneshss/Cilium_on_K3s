export AGENT_IP=$(ip a |grep global | grep -v '10.0.2.15' | awk '{print $2}' | cut -f1 -d '/')
export MASTER_IP=$(cat /vagrant/master-ip)
export NODE_TOKEN=$(cat /vagrant/node-token)

#export K3S_URL=https://192.68.80.10:6443
K3S_URL=https://192.68.80.10:6443

sudo mount bpffs -t bpf /sys/fs/bpf

curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN="${NODE_TOKEN}" INSTALL_K3S_EXEC="--node-ip=${AGENT_IP} --node-external-ip=${AGENT_IP}" sh -

#curl -sfL https://get.k3s.io |    K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN="K10ea7f32dc39ff1c9fe6544731b971d391ed210110698d55f481a08716ec986be6::server:bf8273bf0430228eae9db2da314454cd"  K3S_FLANNEL_BACKEND=none  INSTALL_K3S_EXEC="--node-ip=${AGENT_IP} --node-external-ip=${AGENT_IP}" sh -
#export K3S_URL=https://192.68.80.10:6443
#K3S_URL=https://192.68.80.10:6443
systemctl enable --now k3s-agent
