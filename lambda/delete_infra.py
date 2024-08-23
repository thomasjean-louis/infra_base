import urllib.request
import json
import os
from pprint import pprint
import boto3 

def lambda_handler(event, context):
  
  # # Destroy terraform stack
  # url = "https://api.github.com/repos/thomasjean-louis/infra/actions/workflows/deleteResources.yml/dispatches"
  
  # values = {"ref": os.environ["DEPLOYMENT_BRANCH"],}
  # headers = {
  #   "Accept": "application/vnd.github+json",
  #   "Authorization": "Bearer "+os.environ["TOKEN_GITHUB"],
  #   "X-GitHub-Api-Version": "2022-11-28",
  # }
  
  # data = json.dumps(values).encode("utf-8")
  # pprint(data)

  # try:
  #   req = urllib.request.Request(url, data, headers)
  #   with urllib.request.urlopen(req) as f:
  #       res = f.read()
  #   pprint(res.decode())
  # except Exception as e:
  #   pprint(e)

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
                  'TTL': record['ResourceRecords'][0]['TTL'],
                  'Type': 'CNAME',
              },
           },
        ],
         },
        HostedZoneId = os.environ["HOSTED_ZONE_ID"],
      )

      


    
  