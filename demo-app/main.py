"""Instrumented demo application for the observability stack."""

import logging
import os
import random
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "demo-app")
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")

resource = Resource.create(
    {
        "service.name": SERVICE_NAME,
        "service.version": os.getenv("OTEL_RESOURCE_ATTRIBUTES", "1.0.0").split("service.version=")[-1].split(",")[0],
        "deployment.environment": os.getenv("DEPLOYMENT_ENVIRONMENT", "development"),
    }
)

trace_provider = TracerProvider(resource=resource)
trace_provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=f"{OTLP_ENDPOINT}/v1/traces"))
)
trace.set_tracer_provider(trace_provider)

metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=f"{OTLP_ENDPOINT}/v1/metrics"),
    export_interval_millis=10000,
)
metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[metric_reader]))

LoggingInstrumentor().set_logging_format()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

meter = metrics.get_meter(__name__)
request_counter = meter.create_counter("demo_requests_total", description="Total demo requests")
latency_histogram = meter.create_histogram("demo_request_duration_seconds", description="Request latency")


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("demo-app starting", extra={"service": SERVICE_NAME})
    yield
    logger.info("demo-app shutting down")


app = FastAPI(title="Observability Demo App", version="1.0.0", lifespan=lifespan)
FastAPIInstrumentor.instrument_app(app)


@app.middleware("http")
async def observe_requests(request: Request, call_next):
    start = time.perf_counter()
    response: Response = await call_next(request)
    duration = time.perf_counter() - start
    attrs = {"http.route": request.url.path, "http.method": request.method, "http.status_code": response.status_code}
    request_counter.add(1, attrs)
    latency_histogram.record(duration, attrs)
    return response


@app.get("/health")
async def health():
    return {"status": "ok", "service": SERVICE_NAME}


@app.get("/metrics")
async def metrics_endpoint():
    return JSONResponse({"note": "metrics exported via OTLP to collector"})


@app.get("/api/work")
async def do_work(fail_rate: float = 0.1):
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("process_work") as span:
        delay = random.uniform(0.05, 0.5)
        span.set_attribute("work.delay_seconds", delay)
        time.sleep(delay)

        if random.random() < fail_rate:
            logger.error("simulated failure during work", extra={"fail_rate": fail_rate})
            span.set_status(trace.Status(trace.StatusCode.ERROR, "simulated failure"))
            return JSONResponse(status_code=500, content={"error": "simulated failure"})

        logger.info("work completed", extra={"delay": round(delay, 3)})
        return {"status": "done", "delay": round(delay, 3)}


@app.get("/api/chain")
async def chain_call():
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("chain_parent"):
        with tracer.start_as_current_span("chain_child_a"):
            time.sleep(random.uniform(0.02, 0.1))
        with tracer.start_as_current_span("chain_child_b"):
            time.sleep(random.uniform(0.02, 0.15))
        logger.info("chain call completed")
        return {"status": "chained", "spans": 3}
