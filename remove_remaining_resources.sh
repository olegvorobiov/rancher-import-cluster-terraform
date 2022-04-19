#!/bin/bash

kubectl delete clusterrolebinding proxy-role-binding-kubernetes-master
kubectl delete clusterrole proxy-clusterrole-kubeapiserver
