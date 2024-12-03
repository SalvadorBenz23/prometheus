from flask import Flask, make_response, request
from prometheus_client import Counter, Histogram, CollectorRegistry, generate_latest
import random
import time

# Flask app parameters
app = Flask('my app')
address = '0.0.0.0'
port = 5000

# Prometheus metrics
collector = CollectorRegistry()

# Define metrics
nb_of_requests_counter = Counter(
    name='nb_of_requests',
    documentation='number of requests per method or per endpoint',
    labelnames=['method', 'endpoint'],
    registry=collector
)
duration_of_requests_histogram = Histogram(
    name='duration_of_requests',
    documentation='duration of requests per method or endpoint',
    labelnames=['method', 'endpoint'],
    registry=collector
)

# Define the app's root endpoint
@app.route('/', methods=['GET', 'POST'])
def index():
    start = time.time()
    method_label = request.method
    endpoint_label = '/'
    nb_of_requests_counter.labels(method=method_label, endpoint=endpoint_label).inc()

    # Simulate processing time
    waiting_time = round(random.uniform(0, 1) * 2, 3)
    time.sleep(waiting_time)

    stop = time.time()
    duration_of_requests_histogram.labels(method=method_label, endpoint=endpoint_label).observe(stop - start)

    return f"This request took {waiting_time}s"

# Define the custom metrics endpoint
@app.route('/my_metrics', methods=['GET', 'POST'])
def my_metrics():
    response = make_response(generate_latest(collector))
    response.headers['Content-Type'] = 'text/plain'
    return response

if __name__ == '__main__':
    app.run(host=address, port=port)
