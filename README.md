# NOTES

## PING
ansible -i inventory/dev.yaml all -m ping

## SOLUTION 
!["inventory_yaml_file"](images/inventory_yaml.png)

## Lesson Learned
<br>1. yml file NOT yaml file (ansible will not recognize it)
<br>2. hosts: / <server_name> / ansible_host (ansible_host is required)


## Error1

"[WARNING]:  * Failed to parse /home/angel.cruz/sandbox/repos/pulumi-aws-1/ansible/inventory/dev.yaml
with ini plugin: Invalid host pattern 'webservers:' supplied, ending in ':' is not allowed, this
character is reserved to provide a port."
<br>
This warning means Ansible is trying to treat your dev.yaml as a YAML inventory plugin config file, but it doesn't have the required plugin key at the root.

<br>How to fix:<br>

If dev.yaml is a static YAML inventory:
<br>Make sure it follows the YAML inventory format:

<br>Example:


<br># filepath: /home/angel.cruz/sandbox/repos/pulumi-aws-1/ansible/inventory/dev.yaml
<br>all:  
<br>  hosts:    
<br>    server1:      
<br>      ansible_host: 34.221.233.84    
<br>    server2:      
<br>      ansible_host: 34.221.86.243  
<br>   vars:    
<br>     ansible_user: ubuntu    
<br>     ansible_ssh_private_key_file: /home/angel.cruz/.ssh/id_rsa

