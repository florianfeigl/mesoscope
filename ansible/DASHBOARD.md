# Dashboard Integration Notes

Future dashboard for visualizing cell analysis data.

## Planned Features

- **Annotation Progress**: Track images annotated vs pending
- **Model Performance**: mAP, precision, recall over training epochs
- **Cell Statistics**: Counts per class, size distributions
- **Experiment Timeline**: Images captured over time
- **Inference Metrics**: FPS, latency on Hailo-8

## Tech Stack Options

| Tool | Pros | Cons |
|------|------|------|
| **Grafana** | Rich visualizations, time-series | Heavy, overkill for simple dashboards |
| **Redash** | SQL-based, easy setup | Less real-time |
| **Custom FastAPI + HTMX** | Lightweight, full control | More development |
| **Streamlit** | Python-native, quick prototyping | Less customizable |

## Recommended: Caddy + FastAPI + HTMX

```
VPS Structure:
├── CVAT (cvat.feigl.dev)      - Annotation
├── Dashboard (dash.feigl.dev) - Analytics
└── Caddy                      - Reverse proxy + HTTPS
```

## Integration Points

1. **CVAT API** - Pull annotation statistics
   - Projects count, images annotated
   - Per-class object counts

2. **Model Training Logs** - Parse Ultralytics output
   - mAP, loss curves
   - Export to SQLite/PostgreSQL

3. **Pi Data Collection** - Track capture sessions
   - Images per experiment
   - Time-lapse progress

## Next Steps

1. Deploy CVAT first (current priority)
2. Collect and annotate data
3. Build dashboard after training pipeline is operational

## Caddy Configuration (Future)

```Caddyfile
cvat.feigl.dev {
    reverse_proxy localhost:8080
}

dash.feigl.dev {
    reverse_proxy localhost:8000
}
```
