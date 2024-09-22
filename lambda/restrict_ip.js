function handler(event) {
  const request = event.request;
  const clientIP = event.viewer.ip;

  const WHITELISTED_IP = ["ip"];

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
