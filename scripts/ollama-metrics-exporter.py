#!/usr/bin/env python3
"""
Ollama Metrics Exporter for Prometheus
Exposes Ollama API metrics in Prometheus format
"""

import requests
import json
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import logging

# Configuration
OLLAMA_URL = "http://localhost:11434"
METRICS_PORT = 9101
UPDATE_INTERVAL = 30  # seconds

class MetricsCollector:
    def __init__(self):
        self.metrics = {}
        self.last_update = 0
        
    def collect_metrics(self):
        """Collect metrics from Ollama API"""
        try:
            # Get running models
            response = requests.get(f"{OLLAMA_URL}/api/ps", timeout=5)
            if response.status_code == 200:
                data = response.json()
                models = data.get('models', [])
                self.metrics['ollama_loaded_models'] = len(models)
                
                # Calculate total VRAM usage
                total_vram = sum(model.get('size_vram', 0) for model in models)
                self.metrics['ollama_vram_usage_bytes'] = total_vram
                
                # Model-specific metrics
                for model in models:
                    model_name = model.get('name', 'unknown').replace(':', '_').replace('/', '_')
                    self.metrics[f'ollama_model_size_vram_bytes{{model="{model_name}"}}'] = model.get('size_vram', 0)
                    self.metrics[f'ollama_model_size_bytes{{model="{model_name}"}}'] = model.get('size', 0)
            else:
                self.metrics['ollama_loaded_models'] = 0
                self.metrics['ollama_vram_usage_bytes'] = 0
                
            # Test API responsiveness
            start_time = time.time()
            response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                self.metrics['ollama_api_response_time_seconds'] = response_time
                self.metrics['ollama_api_up'] = 1
                
                # Count available models
                data = response.json()
                available_models = len(data.get('models', []))
                self.metrics['ollama_available_models'] = available_models
            else:
                self.metrics['ollama_api_up'] = 0
                self.metrics['ollama_api_response_time_seconds'] = 0
                
        except Exception as e:
            logging.error(f"Error collecting metrics: {e}")
            self.metrics['ollama_api_up'] = 0
            
        self.last_update = time.time()
    
    def get_prometheus_metrics(self):
        """Format metrics in Prometheus format"""
        if time.time() - self.last_update > UPDATE_INTERVAL:
            self.collect_metrics()
            
        output = []
        output.append("# HELP ollama_api_up Whether Ollama API is responding")
        output.append("# TYPE ollama_api_up gauge")
        output.append(f"ollama_api_up {self.metrics.get('ollama_api_up', 0)}")
        
        output.append("# HELP ollama_api_response_time_seconds API response time")
        output.append("# TYPE ollama_api_response_time_seconds gauge")
        output.append(f"ollama_api_response_time_seconds {self.metrics.get('ollama_api_response_time_seconds', 0)}")
        
        output.append("# HELP ollama_loaded_models Number of currently loaded models")
        output.append("# TYPE ollama_loaded_models gauge")
        output.append(f"ollama_loaded_models {self.metrics.get('ollama_loaded_models', 0)}")
        
        output.append("# HELP ollama_available_models Number of available models")
        output.append("# TYPE ollama_available_models gauge")
        output.append(f"ollama_available_models {self.metrics.get('ollama_available_models', 0)}")
        
        output.append("# HELP ollama_vram_usage_bytes Total VRAM usage in bytes")
        output.append("# TYPE ollama_vram_usage_bytes gauge")
        output.append(f"ollama_vram_usage_bytes {self.metrics.get('ollama_vram_usage_bytes', 0)}")
        
        # Model-specific metrics
        for key, value in self.metrics.items():
            if key.startswith('ollama_model_'):
                metric_name = key.split('{')[0]
                if '{' in key:
                    labels = key.split('{')[1].rstrip('}')
                    output.append(f"{metric_name}{{{labels}}} {value}")
                else:
                    output.append(f"{metric_name} {value}")
        
        return '\n'.join(output)

class MetricsHandler(BaseHTTPRequestHandler):
    def __init__(self, collector, *args):
        self.collector = collector
        super().__init__(*args)
        
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(self.collector.get_prometheus_metrics().encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress HTTP logs
        pass

def main():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    
    collector = MetricsCollector()
    
    def handler(*args):
        MetricsHandler(collector, *args)
    
    server = HTTPServer(('0.0.0.0', METRICS_PORT), handler)
    
    logging.info(f"Starting Ollama metrics exporter on port {METRICS_PORT}")
    logging.info(f"Metrics available at http://localhost:{METRICS_PORT}/metrics")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down...")
        server.shutdown()

if __name__ == "__main__":
    main()
