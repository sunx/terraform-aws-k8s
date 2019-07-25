[Unit]
Description=etcd
Documentation=https://github.com/coreos


[Service]
ExecStart=/usr/local/bin/etcd \
   --advertise-client-urls=https://${HOSTETCD}:2379 \
   --cert-file=/etc/kubernetes/pki/etcd/server.crt \
   --client-cert-auth=true \
   --data-dir=/var/lib/etcd \
   --initial-advertise-peer-urls=https://${HOSTETCD}:2380 \
   --initial-cluster=${initial-cluster} \
   --initial-cluster-state=new \
   --key-file=/etc/kubernetes/pki/etcd/server.key \
   --listen-client-urls=https://${HOSTETCD}:2379 \
   --listen-peer-urls=https://${HOSTETCD}:2380 \
   --name=${NAME} \
   --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt \
   --peer-client-cert-auth=true \
   --peer-key-file=/etc/kubernetes/pki/etcd/peer.key \
   --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \
   --snapshot-count=10000 \
   --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
Restart=on-failure
RestartSec=5



[Install]
WantedBy=multi-user.target
