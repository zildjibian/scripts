# put in your wave folder (you must have python installed)

from http.server import BaseHTTPRequestHandler, HTTPServer
import os

os.system('title readfile() handler')

script_directory = os.path.dirname(os.path.abspath(__file__))

workspace = script_directory + "\\workspace"

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.replace('>', " ")
        print('requested', path)

        self.send_response(200)
        
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        try:
            f = open(workspace + path, "rb").read()
        except: f = b'file not found'
        
        if "../" in path: f = b'nah bro' # idk... this is so vuln i guess...?????
        
        self.wfile.write(f)

    def version_string(self):
        return 'SimpleHTTP/0.6'
        
    def log_message(self, format, *args):
        pass

host = 'localhost'
port = 8612

server = HTTPServer((host, port), SimpleHTTPRequestHandler)

print(f'Server running on {host}:{port}')
server.serve_forever()
