#!/bin/bash
set -e

echo "🚀 Deploying to production environment..."

# Parse instance IPs
IFS=',' read -ra INSTANCES <<< "$PRODUCTION_INSTANCE_IPS"

for INSTANCE_IP in "${INSTANCES[@]}"; do
    echo "📦 Deploying to instance: $INSTANCE_IP"
    
    # Create SSH key file
    echo "$PRODUCTION_SSH_KEY" > /tmp/production-key.pem
    chmod 600 /tmp/production-key.pem

    # Copy build artifact
    scp -i /tmp/production-key.pem -o StrictHostKeyChecking=no \
        drupal-build-*.tar.gz ubuntu@$INSTANCE_IP:/tmp/

    # Execute deployment on instance
    ssh -i /tmp/production-key.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP << 'EOF'
        # Backup current deployment
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        sudo cp -r /var/www/html /var/www/html.backup-$TIMESTAMP
        
        # Extract build
        tar -xzf /tmp/drupal-build-*.tar.gz -C /var/www/html/
        
        # Restore settings.php if it exists in backup
        if [ -f /var/www/html.backup-$TIMESTAMP/sites/default/settings.php ]; then
            sudo cp /var/www/html.backup-$TIMESTAMP/sites/default/settings.php /var/www/html/sites/default/
        fi
        
        # Set permissions
        sudo chown -R www-data:www-data /var/www/html/
        sudo find /var/www/html/ -type d -exec chmod 755 {} \;
        sudo find /var/www/html/ -type f -exec chmod 644 {} \;
        sudo chmod 775 /var/www/html/sites/default/files/
        sudo chmod 440 /var/www/html/sites/default/settings.php
        
        # Clear cache
        sudo rm -rf /var/www/html/sites/default/files/cache/*
        sudo rm -rf /var/www/html/sites/default/files/php/*
        
        # Run database updates if needed
        cd /var/www/html && sudo -u www-data php core/scripts/drupal.sh update
        
        # Restart Apache
        sudo systemctl restart apache2
        
        # Cleanup
        rm /tmp/drupal-build-*.tar.gz
EOF

    echo "✅ Deployment to $INSTANCE_IP completed!"
done

# Cleanup
rm /tmp/production-key.pem
echo "🎉 Production deployment completed successfully!"