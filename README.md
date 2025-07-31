# NOTES

## SHELL
<br> -m shell -a <shell executable>
<br>
```
ansible webservers -i inventory/dev.yml -m shell -a "free -m"
```
<br>(NOTE: use module 'shell' with arguments 'free -m')<br>

<br>*RESULT*
jenkins1 | CHANGED | rc=0 >> <br>


|               | Total     | Used  |free  |shared|buff/cache|available|
| ------------- |:---------:| -----:|-----:|-----:|    -----:|   -----:|
| Mem:          | 954       |187    |218   |0     |548       |605      |
| Swap:         |0          |0      |0

<br>other shell commands:
<br> ```ansible webservers -i inventory/dev.yml -m shell -a "cat /etc/os-release"```

***NOTE:***
To see what available modules exist for ansible:<br>
```ansible-doc -l```


## PING
<br> the '-m ping' below means **module 'ping'**

<br>*ALL*

```
ansible -i inventory/dev.yaml all -m ping
```
*INDIVIDUAL* <br>
```ansible jenkins1 -i inventory/dev.yml -m ping``` <br>
OR <br>
```ansible server2 -i inventory/dev.yml -m ping``` <br>

(NOTE: reference it with the name given above 'ansible_host') <br>

*BY GROUP* <br>
```ansible webservers -i inventory/dev.yml -m ping``` <br>
(NOTE: 'webservers' is the group name) <br>

---

## Error 1: bad format of YAML inventory

## SOLUTION 
!["inventory_yaml_file"](images/inventory_yaml.png)

## Lesson Learned
<br>1. yml file NOT yaml file (ansible will not recognize it)
<br>2. hosts: / <server_name> / ansible_host (ansible_host is required)


## Error 1 Message

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

