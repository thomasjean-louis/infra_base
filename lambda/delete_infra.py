import urllib.request
import json
import os
from pprint import pprint
import boto3 

def lambda_handler(event, context):
  
  # Delete Cloudformation stacks
  cf_stacks = boto3.client('cloudformation')
  stacks = cf_stacks.list_stacks(StackStatusFilter=['CREATE_COMPLETE', 'UPDATE_COMPLETE'])
  for stack in stacks['StackSummaries']:
    stack_name = stack['StackName']
    print(f"Deleting stack: {stack_name}")
    cf_stacks.delete_stack(StackName=stack_name)

    # Wait for the stack to be deleted
    while True:
        try:
            status = cf_stacks.describe_stacks(StackName=stack_name)['Stacks'][0]['StackStatus']
        except:
            print(f"Error when deleting stack {stack_name}")
            break
        if status == 'DELETE_COMPLETE':
            print(f"Stack {stack_name} has been deleted")
            break
        time.sleep(5)


  # Remove acm-validation Records
  client53 = boto3.client('route53')
  response53 = client53.list_resource_record_sets(
    HostedZoneId = os.environ["HOSTED_ZONE_ID"]
  )

  dns_records = []    
  dns_records.extend(response53['ResourceRecordSets'])

  for record in dns_records:
    if (record['Type'] == 'CNAME') and ("acm-validations.aws" in record['ResourceRecords'][0]['Value']) :
        
      # delete this record
      client53.change_resource_record_sets(
        ChangeBatch={
          'Changes': [
           {
              'Action': 'DELETE',
              'ResourceRecordSet': {
                  'Name': record['Name'],
                  'ResourceRecords': [
                      {
                          'Value': record['ResourceRecords'][0]['Value'],
                      },
                  ],
                  'TTL': record['TTL'],
                  'Type': 'CNAME',
              },
           },
        ],
         },
        HostedZoneId = os.environ["HOSTED_ZONE_ID"],
      )

  # # Destroy terraform stack
  url = "https://api.github.com/repos/thomasjean-louis/infra/actions/workflows/deleteResources.yml/dispatches"
  
  values = {"ref": os.environ["DEPLOYMENT_BRANCH"],}
  headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": "Bearer "+os.environ["TOKEN_GITHUB"],
    "X-GitHub-Api-Version": "2022-11-28",
  }
  
  data = json.dumps(values).encode("utf-8")
  pprint(data)

  try:
    req = urllib.request.Request(url, data, headers)
    with urllib.request.urlopen(req) as f:
        res = f.read()
    pprint(res.decode())
  except Exception as e:
    pprint(e)

  

      


    
  