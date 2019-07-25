apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}"
networking:
  dnsDomain: ${DOMAIN}
  podSubnet: "${KSSUBNET}"
etcd:
    local:
        serverCertSANs:
        - ${HOSTETCD}
        peerCertSANs:
        - ${HOSTETCD}
        extraArgs:
            initial-cluster: ${initial-cluster}
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOSTETCD}:2380
            listen-client-urls: https://${HOSTETCD}:2379
            advertise-client-urls: https://${HOSTETCD}:2379
            initial-advertise-peer-urls: https://${HOSTETCD}:2380
