import urllib.request
import json
import os
from pprint import pprint

def lambda_handler(event, context):
  
  
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
    
  