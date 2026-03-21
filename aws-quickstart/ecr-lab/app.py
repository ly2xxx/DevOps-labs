from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        message = '''
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>🐳 ECR Lab - Hello from Docker!</h1>
            <p>This container was pulled from AWS ECR</p>
            <p>Image built on: <code>v1.0</code></p>
          </body>
        </html>
        '''
        self.wfile.write(message.encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), SimpleHandler)
    print('Server running on port 8080...')
    server.serve_forever()
