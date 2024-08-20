import urllib.parse
import urllib.request
import os

def lambda_handler(event, context):
  data = urllib.parse.urlencode({'ref': os.environ["DEPLOYMENT_BRANCH"]})
  data = data.encode('ascii')

  req = urllib.request.Request('https://api.github.com/repos/thomasjean-louis/infra/actions/workflows/deleteResources.yml/dispatches', data=data) 
  req.add_header('Accept', 'application/vnd.github+json')
  req.add_header('Authorization', 'Bearer'+os.environ["TOKEN_GITHUB"])
  req.add_header('X-GitHub-Api-Version', '2022-11-28')
  req.get_method = lambda: 'POST'

  with urllib.request.urlopen(req) as f:
    print(f.read().decode('utf-8'))