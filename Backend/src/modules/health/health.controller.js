export function healthCheck(request, response) {
  response.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
}