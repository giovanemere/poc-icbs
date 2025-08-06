#!/usr/bin/env python
# =============================================================================
# WebLogic Domain Creation Script
# Creates base_domain with AdminServer configuration
# =============================================================================

import os
import sys

# Domain configuration
domain_name = 'base_domain'
domain_path = '/u01/oracle/user_projects/domains/' + domain_name
admin_server_name = 'AdminServer'
admin_port = 7001
admin_username = 'weblogic'
admin_password = os.environ.get('ADMIN_PASSWORD', 'welcome1')

print('Starting domain creation...')
print('Domain Name: ' + domain_name)
print('Domain Path: ' + domain_path)
print('Admin Port: ' + str(admin_port))

try:
    # Read domain template
    print('Reading domain template...')
    readTemplate('/u01/oracle/wlserver/common/templates/wls/wls.jar')
    
    # Configure AdminServer
    print('Configuring AdminServer...')
    cd('Servers/AdminServer')
    set('ListenAddress', '')
    set('ListenPort', admin_port)
    set('Name', admin_server_name)
    
    # Configure security
    print('Configuring security...')
    cd('/')
    cd('Security/base_domain/User/weblogic')
    cmo.setPassword(admin_password)
    
    # Set domain password
    print('Setting domain password...')
    setOption('OverwriteDomain', 'true')
    setOption('ServerStartMode', 'dev')
    
    # Create domain
    print('Creating domain at: ' + domain_path)
    writeDomain(domain_path)
    closeTemplate()
    
    print('Domain creation completed successfully!')
    print('AdminServer will be available at: http://localhost:' + str(admin_port) + '/console')
    print('Username: ' + admin_username)
    print('Password: ' + admin_password)
    
except Exception, e:
    print('Error creating domain: ' + str(e))
    sys.exit(1)

print('Domain creation script finished.')
