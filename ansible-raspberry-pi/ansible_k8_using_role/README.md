# BASH to ANSIBLE for K8

## Bash 

>k8s-cleanup.sh

    #!/bin/bash

    echo "[1/9] Resetting kubeadm..."
    sudo kubeadm reset -f

    echo "[2/9] Stopping and disabling kubelet..."
    sudo systemctl stop kubelet
    sudo systemctl disable kubelet
    sudo rm -rf /etc/systemd/system/kubelet.service.d
    sudo rm -f /etc/systemd/system/kubelet.service
    sudo systemctl daemon-reload

    echo "[3/9] Removing Kubernetes packages..."
    sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni
    sudo apt-get autoremove -y
    sudo apt-get autoclean

    echo "[4/9] Removing Kubernetes and CNI directories..."
    sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/run/kubernetes
    sudo rm -rf /etc/cni /var/lib/cni /etc/cni/net.d
    sudo rm -rf ~/.kube

    echo "[5/9] Removing Flannel or Calico runtime files..."
    sudo rm -rf /var/run/flannel
    sudo rm -rf /var/run/calico

    echo "[6/9] Cleaning up network interfaces..."
    # Delete CNI, Flannel, Calico interfaces if they exist
    for iface in cni0 flannel.1 tunl0; do
    if ip link show $iface &>/dev/null; then
        sudo ip link delete $iface
    fi
    done

    # Delete all Calico interfaces (cali*)
    for iface in $(ip link show | grep cali | awk -F: '{print $2}' | xargs); do
    sudo ip link delete $iface
    done

    echo "[7/9] Flushing iptables and IPVS rules..."
    sudo iptables -F && sudo iptables -X
    sudo iptables -t nat -F && sudo iptables -t nat -X
    sudo iptables -t raw -F && sudo iptables -t raw -X
    sudo iptables -t mangle -F && sudo iptables -t mangle -X

    # Flush IPVS rules (if kube-proxy IPVS mode was used)
    if command -v ipvsadm &>/dev/null; then
    sudo ipvsadm --clear
    fi

    echo "[8/9] Removing logs..."
    sudo rm -rf /var/log/pods /var/log/containers

    # Optional: Remove Docker and container runtimes
    read -p "Do you want to remove Docker and containerd? (y/n): " REMOVE_DOCKER
    if [[ "$REMOVE_DOCKER" =~ ^[Yy]$ ]]; then
    echo "Removing Docker and container runtimes..."
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo rm -rf /var/lib/docker /var/lib/containerd
    fi

    echo "[9/9] Cleanup completed. A reboot is recommended."

>chmod +x k8s-cleanup.sh

Run it:
> ./k8s-cleanup.sh


This script is idempotent (safe to run multiple times) because:

- It checks for interfaces before deleting them.

- It removes directories only if they exist.

- It prompts for Docker removal (so you don’t accidentally delete it).

## Ansible Playbook

k8s-cleanup.yml

    ---
    - name: Kubernetes Cleanup Playbook
    hosts: all
    become: yes
    tasks:

        - name: Reset kubeadm
        command: kubeadm reset -f
        ignore_errors: yes

        - name: Stop and disable kubelet
        systemd:
            name: kubelet
            state: stopped
            enabled: no
        ignore_errors: yes

        - name: Remove kubelet service files
        file:
            path: "{{ item }}"
            state: absent
        loop:
            - /etc/systemd/system/kubelet.service.d
            - /etc/systemd/system/kubelet.service

        - name: Reload systemd
        command: systemctl daemon-reload

        - name: Remove Kubernetes packages
        apt:
            name:
            - kubeadm
            - kubectl
            - kubelet
            - kubernetes-cni
            state: absent
            purge: yes
            autoremove: yes
            autoclean: yes

        - name: Remove Kubernetes and CNI directories
        file:
            path: "{{ item }}"
            state: absent
        loop:
            - /etc/kubernetes
            - /var/lib/kubelet
            - /var/lib/etcd
            - /var/run/kubernetes
            - /etc/cni
            - /var/lib/cni
            - /etc/cni/net.d
            - /var/run/flannel
            - /var/run/calico
            - /root/.kube

        - name: Delete CNI, Flannel, and Calico interfaces if they exist
        shell: |
            ip link show {{ item }} &>/dev/null && ip link delete {{ item }} || true
        with_items:
            - cni0
            - flannel.1
            - tunl0
        ignore_errors: yes

        - name: Delete Calico interfaces (cali*)
        shell: |
            for iface in $(ip link show | grep cali | awk -F: '{print $2}' | xargs); do
            ip link delete $iface || true
            done
        ignore_errors: yes

        - name: Flush iptables
        shell: |
            iptables -F && iptables -X
            iptables -t nat -F && iptables -t nat -X
            iptables -t raw -F && iptables -t raw -X
            iptables -t mangle -F && iptables -t mangle -X
        ignore_errors: yes

        - name: Flush IPVS rules if ipvsadm exists
        shell: ipvsadm --clear
        when: ansible_facts.packages['ipvsadm'] is defined
        ignore_errors: yes

        - name: Remove logs
        file:
            path: "{{ item }}"
            state: absent
        loop:
            - /var/log/pods
            - /var/log/containers

        - name: Optionally remove Docker and container runtimes
        vars_prompt:
            - name: remove_docker
            prompt: "Do you want to remove Docker and container runtimes? (yes/no)"
            private: no
        block:
            - name: Remove Docker packages
            apt:
                name:
                - docker-ce
                - docker-ce-cli
                - containerd.io
                - docker-buildx-plugin
                - docker-compose-plugin
                state: absent
                purge: yes
            when: remove_docker == 'yes'

            - name: Remove Docker directories
            file:
                path: "{{ item }}"
                state: absent
            loop:
                - /var/lib/docker
                - /var/lib/containerd
            when: remove_docker == 'yes'

>Run:

    ansible-playbook -i inventory.yaml k8s-cleanup.yml

## Option 2: Convert to an Ansible Role

>Folder hiearchy:

    ansible_k8s/
    ├── inventory.ini
    ├── deploy_k8s.yml          # Main deployment playbook
    ├── cleanup_k8s.yml         # Optional cleanup playbook
    ├── roles/
    │   ├── k8_setup/
    │   │   ├── tasks/
    │   │   │   ├── main.yml
    │   │   │   ├── control_plane.yml
    │   │   │   ├── workers.yml
    │   │   │   └── cni.yml
    │   │   └── vars/
    │   │       └── main.yml
    │   └── k8_verify/
    │       └── tasks/
    │           └── main.yml




Key Features

✔ Idempotent:

Control plane runs only if /etc/kubernetes/admin.conf does not exist

Worker join runs only if /etc/kubernetes/kubelet.conf does not exist

✔ Token Management:

First run saves k8s_join_command.sh on control plane

Workers fetch the same command via delegate_to

✔ Safe for future workers:

Just add the new worker to inventory.ini and run:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags join_workers --limit new_worker

✔ Cleanup role is optional and manual:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags cleanup

(We keep cleanup separate so you don’t accidentally wipe your cluster.)

Here’s the full solution with:<br>
✔ Idempotent deployment for control plane & workers<br>
✔ Optional cleanup as a separate playbook<br>
✔ Automatic wait-for-ready checks for nodes & pods<br>
✔ Tags for flexibility: control_plane, join_workers, verify, cleanup, and all

✅ Usage Scenarios

1- First-time setup (control + workers + verify)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all

2- Only control plane

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags control_plane

3- Add a new worker node later

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags join_workers --limit new_worker

4- Verify cluster status

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags verify

5- Full cleanup

    ansible-playbook -i inventory.ini cleanup_k8s.yml


## How to use

>First time: control plane only (since workers aren’t ready yet)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags control_plane

>Later: add worker(s)

Put your new worker(s) into [k8_workers] in inventory.ini.

Run:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags join_workers --limit k8_workers


(Or --limit 192.168.1.95 to target one host.)

> Verify cluster health (anytime)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags verify

>Full flow (fresh cluster, everything)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all

> Cleanup (only when you intend to wipe)

    ansible-playbook -i inventory.ini cleanup_k8s.yml


__Notes & Tips__

- The repo/key URLs shown use the new Kubernetes APT repository style. If you pin a different minor version stream, change both the Release.key URL and the repo line to match (e.g., v1.29).

- The roles are idempotent: re-running won’t nuke your cluster or app workloads.

- Workers always request a fresh join token from the controller during join, so you don’t have to babysit token expiry.


>Option A: Run without tags for now

Since tags are not added, just run:

    ansible-playbook -i inventory.ini deploy_k8s.yml


This will:

Configure the control plane (init_control_plane true on your controller)

Skip worker join because join_workers is false for the controller

When you add a worker later, the same command will also join the worker node.


## LATER: OPTION B include tags
__Sample:__

    - name: "[Setup] Initialize Kubernetes control plane"
    include_tasks: init_control_plane.yml
    when: init_control_plane
    tags: [ 'control_plane' ]

    - name: "[Setup] Join Kubernetes workers"
    include_tasks: join_workers.yml
    when: join_workers
    tags: [ 'workers' ]

    - name: "[Setup] Apply CNI plugin"
    include_tasks: cni.yml
    when: init_control_plane
    tags: [ 'cni' ]

Then:

Full setup:
bash

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all

Only control plane:

bash

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags control_plane

✅ Recommended for now: Just run without tags. Later we can add tags and conditionals for incremental runs.

✅ How to use tags now

> First-time setup (control plane + workers + CNI)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all


> Only deploy/upgrade control plane

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags control_plane

> Add new workers later

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags workers


> Verify cluster status without touching anything

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags verify


This setup is idempotent:

- Adding a new worker node won’t reset the control plane or remove running apps.

- Control plane upgrades or redeployments are isolated via tags.

- Verification can run anytime without changing cluster state.

## How to use the tags:

✅ How to run

> First-time setup (control + workers + verification)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all


> Only control plane setup

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags control_plane


> Only join workers

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags workers


> Only verification of nodes/pods

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags verify

✅ Benefits

Adding a new worker later: just ensure it’s in the inventory under k8_worker group and run --tags workers. Existing control plane and apps remain untouched.

Adding another control plane node in future: tag it control_plane without affecting existing nodes.

Verification is separated with verify tag for safety.

2️⃣ How to safely run the playbook

> Regular deployment / adding nodes:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags setup,workers,control_plane,verify


> Only clean/reset the cluster (dangerous, will purge apps):

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags cleanup


> Adding a new worker later:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags workers


> Only verify cluster health:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags verify


This change protects your deployed apps and makes incremental cluster expansion safe.

✅ Notes:

No tasks in deploy_k8s.yml will purge packages unless you run with --tags cleanup.

New workers can safely join by running the same playbook with --tags workers.

3️⃣ Recommended tag usage


|Task	|Tag |
|-------|----|
|Cleanup cluster|	--tags cleanup
|Setup control plane|	--tags control_plane
|Setup/add worker nodes|	--tags workers
|Verify cluster|	--tags verify
|Full first-time deployment|	--tags setup,control_plane,workers,verify

This layout:
- Protects existing apps.

- Allows incremental cluster expansion (new workers).

- Makes verification independent of deployment.

- Only runs destructive cleanup if explicitly requested.

✅ How to use with your playbook

> First-time deployment (control only, no workers yet)

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all


Only controller1 will run init_control_plane.

Workers section is empty, so nothing runs there.

> Adding a worker later

Reinstall Raspberry Pi OS on the worker, make sure SSH works.

Add the worker to the [k8_worker] section, e.g.:

    [k8_worker]
    worker1 ansible_host=192.168.1.95 ansible_user=pi

> Rerun the same playbook:

    ansible-playbook -i inventory.ini deploy_k8s.yml --tags all


The new worker automatically joins the existing cluster.

Existing apps and pods remain intact on the control plane and any existing workers.

Notes

Keep control plane node first in [k8_controller].

Comment out future workers until their OS is ready to avoid failures.

The playbook is idempotent, so rerunning is safe.