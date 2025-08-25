## ANSIBLE: create k8 worker pod

Folder Structure:<br>

    kubernetes-add-worker/
    ├── inventory
        └── inventory.ini
    ├── playbook.yml
    └── roles/
        └── k8s_worker_join/
            ├── tasks/
            │   └── main.yml
            └── defaults/
                └── main.yml

### Step 1: Create the Ansible role

    ansible-galaxy init roles/k8s_worker_join --force

### Step 2: Define role variables
Add variables to roles/k8s_worker_join/defaults/main.yml. This makes the role configurable and reusable

