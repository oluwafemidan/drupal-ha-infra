#!/bin/bash
set -e

echo "🚀 Deploying to staging environment..."

# Parse instance IPs
IFS=',' read -ra INSTANCES <<< "$STAGING_INSTANCE_IPS"

for INSTANCE_IP in "${INSTANCES[@]}"; do
    echo "📦 Deploying to instance: $INSTANCE_IP"
    
    # Create SSH key file
    echo "$STAGING_SSH_KEY" > /tmp/staging-key.pem
    chmod 600 /tmp/staging-key.pem

    # Copy build artifact
    scp -i /tmp/staging-key.pem -o StrictHostKeyChecking=no \
        drupal-build-*.tar.gz ubuntu@$INSTANCE_IP:/tmp/

    # Execute deployment on instance
    ssh -i /tmp/staging-key.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP << 'EOF'
        # Extract build
        tar -xzf /tmp/drupal-build-*.tar.gz -C /var/www/html/
        
        # Set permissions
        sudo chown -R www-data:www-data /var/www/html/
        sudo find /var/www/html/ -type d -exec chmod 755 {} \;
        sudo find /var/www/html/ -type f -exec chmod 644 {} \;
        sudo chmod 775 /var/www/html/sites/default/files/
        
        # Clear cache
        sudo rm -rf /var/www/html/sites/default/files/cache/*
        sudo rm -rf /var/www/html/sites/default/files/php/*
        
        # Restart Apache
        sudo systemctl restart apache2
        
        # Cleanup
        rm /tmp/drupal-build-*.tar.gz
EOF

    echo "✅ Deployment to $INSTANCE_IP completed!"
done

# Cleanup
rm /tmp/staging-key.pem
echo "🎉 Staging deployment completed successfully!"