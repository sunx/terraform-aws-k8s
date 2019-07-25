apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}"
networking:
  dnsDomain: ${DOMAIN}
  podSubnet: "${KSSUBNET}"
etcd:
    external:
        endpoints:
${ENDPOINTS}
        caFile: /etc/kubernetes/pki/etcd/ca.crt
        certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
        keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
