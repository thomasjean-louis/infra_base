
def lambda_handler(event, context):
  request = event.request
  clientIP = event.viewer.ip

  WHITELISTED_IP = [
     os.environ["WHITELISTED_IP"],
    ]
  shouldAllowIP = WHITELISTED_IP.includes(clientIP)
  if shouldAllowIP:
    #Allow the original request to pass through
    return request
  else:
    response = {
            statusCode: 403,
            message: 'FORBIDDEN',
            details: 'IP address not authorized'
    }
    # Send error message
    return response
    
