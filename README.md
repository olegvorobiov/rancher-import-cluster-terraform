# Tested on Rancher 2.6.3

This repo helps to automate adding of an existing cluster to Rancher Server. What I did originally was I created an imported cluster, then followed the link to yaml manifest from the bootstrap command and converted that manifest into  terraform objects using kubernetes provider.

### Required items
- kubeconfig file for your downstream cluster or other way to authenticate with the downstream cluster, see kubernetes provider documentation
- URL for your Rancher Server
- API key for a user with admin privileges
- CA_CHECKSUM and INSTALL_UUID can be obtained from the manifest

### Problems

The main problem is that terraform destroy command will not remove the cluster, for that reason there is a [script to remove a cluster](delete_cluster.sh) script that removes the cluster with API calls. After all of the resources in kubernetes.tf file are added there will be multiple additional resources added to the cluster, and since those aren't listed in the manifest it won't remove them.

If you would to add that cluster again with Terraform you need to run [script to remove resources that are left](remove_remaining_resources.sh) script on a downstream cluster, otherwise when you apply your terraform code it will throw an error because the resource with the same name is already there.