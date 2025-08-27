#!/bin/bash

# Initialize and apply Terraform
echo "Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# Get outputs from Terraform
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
INSTANCE_IPS=$(terraform output -json instance_public_ips)

# Generate SSH key pair for file synchronization if not exists
if [ ! -f "../ansible/files/sync_key" ]; then
    echo "Generating SSH key pair for file synchronization..."
    ssh-keygen -t rsa -b 4096 -f ../ansible/files/sync_key -N "" -q
    # Copy the same keys to the role directory for Ansible deployment
    cp ../ansible/files/sync_key.pub ../ansible/roles/drupal/files/sync_key.pub
    cp ../ansible/files/sync_key ../ansible/roles/drupal/files/sync_key
fi

# Update Ansible inventory
echo "Updating Ansible inventory..."
cd ../ansible

# Read the template and replace variables
INSTANCE_1_IP=$(echo $INSTANCE_IPS | jq -r '.[0]')
INSTANCE_2_IP=$(echo $INSTANCE_IPS | jq -r '.[1]')

# Use sed to replace placeholders with actual IPs
sed -e "s/\${drupal_instance_1_ip}/$INSTANCE_1_IP/g" \
    -e "s/\${drupal_instance_2_ip}/$INSTANCE_2_IP/g" \
    inventory.tpl > inventory.ini

# Alternatively, you can use this simpler approach:
cat > inventory.ini << EOL
[drupal_servers]
drupal-instance-1 ansible_host=$INSTANCE_1_IP
drupal-instance-2 ansible_host=$INSTANCE_2_IP

[drupal_servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/your-key.pem
ansible_python_interpreter=/usr/bin/python3
sync_master_node=drupal-instance-1
EOL

# Run Ansible playbook
echo "Configuring Drupal servers with Ansible..."
ansible-playbook -i inventory.ini playbook.yml \
  -e "DB_NAME=drupaldb" \
  -e "DB_USER=drupaladmin" \
  -e "DB_PASSWORD=your_db_password" \
  -e "DB_HOST=$RDS_ENDPOINT"

echo "Deployment complete!"
echo "Drupal is available at: http://$ALB_DNS"
echo "File synchronization is configured to run every 5 minutes"