#!/usr/bin/env python3
"""
Mock implementation of AWS Backup service for LocalStack testing.
This script implements the minimal set of Backup API endpoints needed for testing.
"""
import json
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

# In-memory storage for mock data
mock_data = {
    'backup_vaults': {},
    'backup_plans': {},
    'backup_selections': {},
    'iam_roles': {}
}

class MockBackupHandler(BaseHTTPRequestHandler):
    """Handler for mock Backup API requests."""
    
    def _set_headers(self, status_code=200):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('x-amzn-RequestId', 'mocked-request-id')
        self.end_headers()
    
    def _send_json_response(self, data, status_code=200):
        self._set_headers(status_code)
        self.wfile.write(json.dumps(data).encode('utf-8'))
    
    def _send_error(self, code, message):
        self._send_json_response({
            'Error': {
                'Code': code,
                'Message': message,
                'Type': 'Sender'
            }
        }, status_code=400)
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/':
            self._send_json_response({
                'BackupVaults': list(mock_data['backup_vaults'].values()),
                'NextToken': None
            })
        else:
            self._send_error('404', 'Not Found')
    
    def do_POST(self):
        """Handle POST requests."""
        content_length = int(self.headers.get('content-length', 0))
        body = self.rfile.read(content_length)
        data = json.loads(body) if content_length > 0 else {}
        
        try:
            action = data.get('Action')
            
            if action == 'CreateBackupVault':
                self._handle_create_backup_vault(data)
            elif action == 'CreateBackupPlan':
                self._handle_create_backup_plan(data)
            elif action == 'CreateBackupSelection':
                self._handle_create_backup_selection(data)
            elif action == 'GetBackupVaultAccessPolicy':
                self._handle_get_backup_vault_access_policy(data)
            else:
                self._send_error('InvalidAction', f'Unsupported action: {action}')
        except Exception as e:
            self._send_error('InternalFailure', str(e))
    
    def _handle_create_backup_vault(self, data):
        """Handle CreateBackupVault API call."""
        vault_name = data.get('BackupVaultName')
        if not vault_name:
            return self._send_error('MissingParameter', 'Missing required parameter: BackupVaultName')
        
        if vault_name in mock_data['backup_vaults']:
            return self._send_error('AlreadyExistsException', 'Backup vault already exists')
        
        arn = f'arn:aws:backup:us-east-1:123456789012:backup-vault/{vault_name}'
        creation_date = time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.gmtime())
        
        mock_data['backup_vaults'][vault_name] = {
            'BackupVaultName': vault_name,
            'BackupVaultArn': arn,
            'CreationDate': creation_date,
            'NumberOfRecoveryPoints': 0
        }
        
        self._send_json_response({
            'BackupVaultName': vault_name,
            'BackupVaultArn': arn,
            'CreationDate': creation_date
        })
    
    def _handle_create_backup_plan(self, data):
        """Handle CreateBackupPlan API call."""
        backup_plan = data.get('BackupPlan')
        if not backup_plan:
            return self._send_error('MissingParameter', 'Missing required parameter: BackupPlan')
        
        plan_name = backup_plan.get('BackupPlanName')
        if not plan_name:
            return self._send_error('MissingParameter', 'Missing required parameter: BackupPlanName')
        
        plan_id = f'plan-{len(mock_data["backup_plans"]) + 1}'
        arn = f'arn:aws:backup:us-east-1:123456789012:backup-plan:{plan_id}'
        creation_date = time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.gmtime())
        
        mock_data['backup_plans'][plan_id] = {
            'BackupPlanId': plan_id,
            'BackupPlanArn': arn,
            'BackupPlan': backup_plan,
            'VersionId': '1',
            'CreationDate': creation_date,
            'CreatorRequestId': 'mocked-request-id',
            'LastExecutionDate': creation_date
        }
        
        self._send_json_response({
            'BackupPlanId': plan_id,
            'BackupPlanArn': arn,
            'CreationDate': creation_date,
            'VersionId': '1'
        })
    
    def _handle_create_backup_selection(self, data):
        """Handle CreateBackupSelection API call."""
        backup_plan_id = data.get('BackupPlanId')
        if not backup_plan_id:
            return self._send_error('MissingParameter', 'Missing required parameter: BackupPlanId')
            
        selection_name = data.get('BackupSelection', {}).get('SelectionName')
        if not selection_name:
            return self._send_error('MissingParameter', 'Missing required parameter: SelectionName')
        
        selection_id = f'selection-{len(mock_data["backup_selections"]) + 1}'
        creation_date = time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.gmtime())
        
        mock_data['backup_selections'][selection_id] = {
            'SelectionId': selection_id,
            'BackupPlanId': backup_plan_id,
            'CreationDate': creation_date,
            **data.get('BackupSelection', {})
        }
        
        self._send_json_response({
            'SelectionId': selection_id,
            'BackupPlanId': backup_plan_id,
            'CreationDate': creation_date
        })
    
    def _handle_get_backup_vault_access_policy(self, data):
        """Handle GetBackupVaultAccessPolicy API call."""
        backup_vault_name = data.get('BackupVaultName')
        if not backup_vault_name:
            return self._send_error('MissingParameter', 'Missing required parameter: BackupVaultName')
        
        # Return a basic policy for any vault
        self._send_json_response({
            'BackupVaultName': backup_vault_name,
            'BackupVaultArn': f'arn:aws:backup:us-east-1:123456789012:backup-vault/{backup_vault_name}',
            'Policy': json.dumps({
                'Version': '2012-10-17',
                'Statement': [
                    {
                        'Effect': 'Allow',
                        'Principal': '*',
                        'Action': [
                            'backup:DescribeBackupVault',
                            'backup:DeleteBackupVault',
                            'backup:PutBackupVaultAccessPolicy',
                            'backup:DeleteBackupVaultAccessPolicy',
                            'backup:GetBackupVaultAccessPolicy',
                            'backup:StartBackupJob',
                            'backup:StartCopyJob',
                            'backup:StartRestoreJob',
                            'backup:ListBackupJobs',
                            'backup:ListCopyJobs',
                            'backup:ListRestoreJobs',
                            'backup:ListRecoveryPointsByBackupVault',
                            'backup:ListRecoveryPointsByResource',
                            'backup:GetBackupVaultNotifications',
                            'backup:PutBackupVaultNotifications',
                            'backup:DeleteBackupVaultNotifications',
                            'backup:GetRecoveryPointRestoreMetadata',
                            'backup:ListTags',
                            'backup:TagResource',
                            'backup:UntagResource'
                        ],
                        'Resource': f'arn:aws:backup:us-east-1:123456789012:backup-vault/{backup_vault_name}'
                    }
                ]
            })
        })

    def _send_error(self, code, message):
        self._send_json_response({
            'Error': {
                'Code': code,
                'Message': message,
                'Type': 'Sender'
            }
        }, status_code=400)

def run(server_class=HTTPServer, handler_class=MockBackupHandler, port=5000):
    """Run the mock server."""
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting mock Backup service on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
