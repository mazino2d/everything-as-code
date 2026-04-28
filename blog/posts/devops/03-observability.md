---
date: 2026-04-28
title: Observability — Seeing Inside Systems You Cannot Predict
---

Picture this: production is down. The on-call engineer opens the monitoring dashboards. CPU is normal. Memory is normal. Error rate is spiking, but the dashboard does not show which requests are failing, which users are affected, or where in the stack the failure originates. The engineer begins guessing — checking logs manually, querying the database, SSH-ing into services one by one.

Forty minutes later, the cause is found. A third-party API started returning malformed responses for one specific request shape. Nothing in the dashboard caught it because nobody had thought to monitor for it.

This is not a monitoring failure. The monitors were working exactly as designed. It is an observability failure — and the difference between the two is the gap between a four-minute recovery and a four-hour one.

---

## Monitoring Is Not Observability

Monitoring and observability are not synonyms. They solve different problems.

**Monitoring** answers questions you already know to ask. You define the failure modes in advance — CPU above 80%, error rate above 5%, latency above 500ms — and the system alerts you when those thresholds are crossed. Monitoring is reactive to *known unknowns*: things you know might go wrong.

**Observability** answers questions you did not know to ask until something went wrong. An observable system lets you explore its internal state arbitrarily — to ask "what was happening at 14:47 for users in Southeast Asia on iOS 17?" without having instrumented that specific question in advance.

The distinction comes from control systems theory. A system is *observable* if its internal state can be inferred from its external outputs. In software, that means: given the telemetry your system emits, can you reconstruct what it was doing at any point in time, in enough detail to answer novel questions?

Most production systems today are *monitored* but not *observable*. They have dashboards. They have alerts. But when something unexpected happens — which is when it matters most — the dashboards show that something is wrong without showing why.

---

## The Unknown Unknowns Problem

Donald Rumsfeld's taxonomy maps onto system failures uncomfortably well:

- **Known knowns**: you know the system can fail this way, you have a monitor for it, you have a runbook. Recovery is fast.
- **Known unknowns**: you know there are failure modes you haven't fully instrumented. You have partial visibility.
- **Unknown unknowns**: failures you didn't anticipate. No monitor catches them. No runbook exists. The only way to diagnose them is to explore.

Monitoring handles known knowns well. It handles known unknowns partially. It is useless against unknown unknowns — by definition, you cannot alert on a condition you didn't know to define.

Unknown unknowns are not edge cases. They are the norm for complex systems. Every novel dependency, every unusual traffic pattern, every interaction between two services that individually look healthy produces failure modes that nobody modelled in advance. The larger and more interconnected the system, the higher the ratio of unknown unknowns to everything else.

Observability is the answer to unknown unknowns. Not because it predicts them — it cannot — but because it gives engineers the tools to investigate freely when they encounter one. The goal is to make any question about system state *answerable*, even if nobody thought to ask it before the incident.

!!! note "The incident you haven't had yet"
    Unknown unknowns are, by definition, impossible to enumerate. The practical implication: invest in observability infrastructure *before* incidents, not as a response to them. By the time you discover a blind spot, you are already in the incident. Instrumentation added during an incident helps the next one, not the current one.

---

## The Three Pillars

Logs, metrics, and traces are the three primary forms of telemetry. They are often described as a stack to "implement," as if the goal is to have all three. That is the wrong frame. Each answers a different class of question — and understanding what each is *for* determines how to use them well.

### Metrics

Metrics are numerical measurements aggregated over time. Request rate, error rate, latency percentiles, CPU utilisation, memory usage. They are cheap to store because they are pre-aggregated — instead of recording every individual request, you record the count, the sum, the 95th percentile.

Metrics are best for **alerting** and **trend detection**. They answer questions like: is the error rate higher than usual? Is latency creeping up over the past hour? Is this service consuming more memory than last week?

What metrics cannot do: help you understand a specific failure. Knowing that error rate spiked at 14:47 tells you something happened. It does not tell you which requests failed, which users were affected, or why.

### Logs

Logs are discrete events emitted by the system at a point in time: a request was received, a database query executed, an exception was thrown. Unlike metrics, logs are not pre-aggregated — they are individual records, which makes them verbose and expensive to store at scale.

Logs are best for **debugging specific incidents**. Once a metric alert fires, logs let you answer: what exactly happened? Which request triggered the exception? What was the payload?

What logs struggle with: understanding the full journey of a request across multiple services. A log entry in Service A tells you what Service A did. It does not tell you what Service A was responding to from Service B, or what Service B did next.

### Traces

Traces record the path of a single request through a distributed system. A trace is composed of *spans* — one span per service the request touched — linked by a shared trace ID. Together they show the full causal chain: Service A called Service B, which called Service C, and the latency in Service C's database query is what made the whole request slow.

Traces are best for **understanding latency and causality in distributed systems**. Without traces, diagnosing cross-service failures requires manually correlating logs from multiple services by timestamp — a process that is slow, error-prone, and miserable.

What traces require: every service in the path must emit spans, and they must be linked by a shared ID propagated through request headers. This requires instrumentation at every service boundary.

### How the three work together

The three pillars are not redundant. They form a diagnostic chain:

```
Metric alert fires → logs explain what happened in the affected service → traces show how it propagated across services
```

A team that has only metrics can detect problems but not diagnose them. A team that has only logs can diagnose problems in a single service but not understand distributed failures. A team that has all three can move from "something is wrong" to "here is exactly what happened and why" in minutes rather than hours.

---

## Cardinality: Why Observability Is Hard

Cardinality is the number of unique values a field can take. A field like `http_method` has low cardinality — five or six possible values. A field like `user_id` has high cardinality — potentially millions of unique values.

High-cardinality fields are what make observability powerful. Being able to ask "what requests did user 8472938 make in the last hour?" requires that `user_id` be a queryable dimension of your telemetry. The same goes for `request_id`, `customer_account`, `deployment_version`, `feature_flag_variant` — any field that identifies a specific entity rather than a category.

The problem: traditional monitoring tools, including most time-series databases, are designed around low-cardinality data. Prometheus, for example, creates a new time series for every unique combination of label values. Adding `user_id` as a Prometheus label with a million users creates a million time series — the database grinds to a halt, and costs explode.

This is why most teams end up with monitoring that looks like observability but isn't. They have Prometheus and Grafana. They have log aggregation. But they stripped high-cardinality fields from their metrics to keep costs manageable, and their logs are not structured in a way that makes arbitrary queries fast.

The architectural implication: tools designed for observability handle high cardinality differently. Instead of pre-aggregating into time series, they store raw events and compute aggregations at query time. This is more expensive per event but allows arbitrary slicing — any field, any combination, any question.

!!! tip "Structured logging is the floor"
    Before worrying about tracing infrastructure or high-cardinality metrics, make sure logs are structured. A JSON log line with named fields — `user_id`, `request_id`, `duration_ms`, `status_code`, `endpoint` — is queryable. A freeform string like `"Error processing request for user 8472938 in 142ms"` is searchable by grep but not aggregatable, filterable, or analytically useful. Structured logging is cheap to implement and the highest-leverage improvement most teams can make immediately.

---

## Back to the Incident

Return to the opening scenario. An observable version of that system would have looked different at 14:47.

The on-call engineer opens not a static dashboard but an exploratory query interface. They filter to requests with elevated latency in the last 30 minutes. They break down by response shape — and immediately see that requests with a specific `content_type` header from the third-party API are failing. They pull the traces for those requests and see the full call chain: the malformed response from the external API, the internal service that failed to parse it, the cascade that followed.

The cause is identified in four minutes, not forty. Not because the engineer was smarter or luckier, but because the system was built to answer questions that nobody had anticipated in advance.

That is what observability actually means: not dashboards, not alerts, not the three pillars as a checklist. It means that when an unknown unknown surfaces — as it always will — the tools exist to understand it quickly.

The DORA research showed that elite teams restore service in under an hour. That is not achievable by guessing. It requires systems that tell you, honestly and in detail, what they are doing.
