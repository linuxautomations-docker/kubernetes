#!/bin/bash

# Kubernetes Node Setup

LOG=/tmp/kube-master.log 
rm -f $LOG

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations-docker/kubernetes/master/common-functions.sh" >/tmp/common-functions.sh
source /tmp/common-functions.sh

## Checking Root User or not.
CheckRoot

## Checking SELINUX Enabled or not.
CheckSELinux

## Checking Firewall on the Server.
CheckFirewall

## Setting Up Docker Repository.
DockerCERepo

## Installing Docker
yum install bind-utils docker-ce http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.21-1.el7.noarch.rpm -y &>/dev/null
#yum install docker -y
if [ $? -eq 0 ]; then  
	success "Installed Docker-CE Successfully"
else
	error "Installing Docker-CE Failure"
	exit 1
fi

## Starting Docker Service
systemctl enable docker &>/dev/null
systemctl start docker &>/dev/null
if [ $? -eq 0 ]; then 
	success "Started Docker Engine Successfully"
else
	error "Starting Docker Engine Failed"
	exit 1
fi

#yum install docker -y &>>$LOG
#systemctl enable docker &>>$LOG
#systemctl start docker  

echo '[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' >/etc/yum.repos.d/kubernetes.repo

yum install -y kubelet kubeadm kubectl &>>$LOG
Stat $? "Installing Kubelet Service"

systemctl enable kubelet  &>/dev/null

#systemctl start kubelet &>>$LOG 
#Stat $? "Starting Kubelet Service"

echo 'net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/k8s.conf
sysctl --system &>> $LOG
Stat $? "Updating Network Configuration" 

sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload &>/dev/null
systemctl restart kubelet &>>$LOG 
Stat $? "Retarting Kubelet Service"

sysctl net.bridge.bridge-nf-call-iptables=1 &>/dev/null 

