import requests
import os

def lambda_handler(event, context):

  headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer'+os.environ["TOKEN_GITHUB"],
    'X-GitHub-Api-Version': '2022-11-28'
  }  

  data = '{"ref":"os.environ["DEPLOYMENT_BRANCH"]"}'
  res = requests.post(' https://api.github.com/repos/thomasjean-louis/infra/actions/workflows/main.yml/dispatches', headers=headers, data=data)