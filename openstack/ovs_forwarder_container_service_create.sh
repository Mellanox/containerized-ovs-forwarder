OVS_FORWARDER_CONTAINER_NAME=ovs_forwarder_container
OVS_FORWARDER_CONTAINER_SERVICE_NAME=ovs_forwarder_container
OVS_FORWARDER_CONTAINER_SERVICE_FILE=\
"/etc/systemd/system/$OVS_FORWARDER_CONTAINER_SERVICE_NAME.service"

OVS_FORWARDER_CONTAINER_SERVICE_CONTENT="""[Unit]
Description=ovs forwarder container
After=sriov_bind.service

[Service]
Restart=oneshot
ExecStart=/usr/bin/podman start $OVS_FORWARDER_CONTAINER_NAME
[Install]
WantedBy=multi-user.target
"""

# Create service file
cat << EOF > $OVS_FORWARDER_CONTAINER_SERVICE_FILE
$OVS_FORWARDER_CONTAINER_SERVICE_CONTENT
EOF

# Enable service
/usr/bin/systemctl enable $OVS_FORWARDER_CONTAINER_SERVICE_NAME

