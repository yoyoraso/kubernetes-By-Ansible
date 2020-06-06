#!/bin/bash


echo "=============Make sure Your Kubernetes Master server is 2 cores============"
echo "=============Press any Key To continu============="
read yaya

sudo hostnamectl set-hostname Ansible-master
echo "Enter Your Ansible Master IP"
read masteranip
echo "
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$masteranip   Ansible-master
" > hostes


echo "Enter Your Kubernetes Master IP"
read masterip
echo "
$masterip   kubernetes-master
" >> hostes

ssh-keygen -t rsa
ssh root@$masterip mkdir -p .ssh
cat .ssh/id_rsa.pub | ssh root@$masterip 'cat >> .ssh/authorized_keys'
ssh root@$masterip "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"

scp ./hostes root@$masterip:/etc/hosts

echo "
#!/bin/bash
sudo hostnamectl set-hostname kubernetes-master
" > worker_scr.sh


scp ./worker_scr.sh root@$masterip:./worker_scr.sh

ssh -t root@$masterip "bash worker_scr.sh"



echo "Enter number of Nodes"
read number
for i in $(seq 1 $number)
do
echo "Enter Your kubernetes  $i Node IP "
read ip
ssh root@$ip mkdir -p .ssh
cat .ssh/id_rsa.pub | ssh root@$ip 'cat >> .ssh/authorized_keys'
ssh root@$ip "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"


echo "
$ip   kubernetes-worker$i
" >> hostes
scp ./hostes root@$ip:/etc/hosts

scp ./hostes root@$masterip:/etc/hosts



echo "
#!/bin/bash
sudo hostnamectl set-hostname kubernetes-worker$i
" > worker_scr.sh
scp ./worker_scr.sh root@$ip:./worker_scr.sh
ssh -t root@$ip "bash worker_scr.sh"

done

cat hostes  > /etc/hosts

sudo yum install -y epel-release
sudo yum install -y ansible
sudo yum install -y git

echo "
[kubernetes-master-nodes]
" > hosts
echo "Enter kubernetes-Master IP"
read masterip
echo "
kubernetes-master ansible_host=$masterip
" >> hosts
echo "
[kubernetes-worker-nodes]
" >> hosts

echo "Enter number of workers"
read number
for i in $(seq 1 $number)
do
echo "Enter kubernetes Node IP "
read ip
echo "
kubernetes-worker$i ansible_host=$ip 
" >> hosts
#echo "Enter Your ssh user"
#read user
#echo "Enter Your ssh Password"
#read pass
#echo "
#[kubernetes:children]
#kubernetes-worker-nodes
#kubernetes-master-nodes
#[kubernetes:vars]
#ansible_password=$pass
#ansible_ssh_user=$user
#" >> hosts 

done

ansible-playbook  settingup_kubernetes_cluster.yml
ansible-playbook  join_kubernetes_workers_nodes.yml

