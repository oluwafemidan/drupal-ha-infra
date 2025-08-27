[drupal_servers]
drupal-instance-1 ansible_host=${drupal_instance_1_ip}
drupal-instance-2 ansible_host=${drupal_instance_2_ip}

[drupal_servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/your-key.pem
ansible_python_interpreter=/usr/bin/python3
sync_master_node=drupal-instance-1