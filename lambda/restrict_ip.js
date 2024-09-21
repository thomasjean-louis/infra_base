const RESTRICT_IP = "${restrict_ip}";

function handler(event) {
  const request = event.request;
  const clientIP = event.viewer.ip;

  // This will contain a list of all IPs we want to allow
  const WHITELISTED_IP = [RESTRICT_IP];

  const shouldAllowIP = WHITELISTED_IP.includes(clientIP);
  if (shouldAllowIP) {
    // Allow the original request to pass through
    return request;
  } else {
    return {
      statusCode: 403,
      body: "IP address not authorised",
    };
  }
}
