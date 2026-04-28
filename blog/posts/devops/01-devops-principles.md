---
date: 2026-04-28
title: The Three Ways — The Principles Behind DevOps
---

Most explanations of DevOps start with tools: Terraform, Kubernetes, CI/CD pipelines. That is the wrong place to start.

Tools are answers. Before reaching for an answer, it helps to understand the question.

The question DevOps is trying to answer: **why does it take so long — and go so wrong — to get working software from a developer's machine into the hands of users?**

Gene Kim, co-author of *The Phoenix Project* and *The DevOps Handbook*, framed the answer as three principles he called The Three Ways. Every practice, tool, and process that works in DevOps can be traced back to one of them.

---

## The First Way: Flow

The First Way is about optimising the *entire* system — from the moment a developer writes code to the moment a user benefits from it. Not optimising individual parts. The whole.

This distinction matters more than it sounds. A team can have excellent individual contributors, fast code reviewers, and reliable deployments, yet still ship slowly — because each hand-off between stages introduces waiting. Code waits for review. A reviewed PR waits for CI. A passed build waits for a deployment window. A deployment waits for a sign-off.

The bottleneck is almost never where people think it is. It is usually in the *gaps between steps*, not the steps themselves.

**Making work visible** is the precondition for improving flow. You cannot optimise what you cannot see. Kanban boards, deployment dashboards, and lead-time metrics are not bureaucracy — they make the invisible visible so that bottlenecks can be identified and attacked.

**Limiting work in progress** is one of the most effective ways to improve flow. It sounds backward, but doing fewer things at the same time helps teams deliver faster. When engineers juggle many tasks, each task slows down because of context switching and blocked dependencies. Teams cannot always finish one task before starting another, but keeping WIP limits tight gets close to that and usually improves throughput.

**Eliminating waste** in the delivery pipeline is the ongoing work. Waste, in lean manufacturing terms, is anything that consumes time or resources but does not add value: waiting, rework, unnecessary approval gates, manual steps that could be automated, documentation written for compliance but never read. Each eliminated waste shortens the feedback loop between intention and outcome.

The First Way asks: how fast can a change travel from an idea to production? That number — lead time — is the most useful single measure of a delivery system's health.

!!! tip "The deployment frequency signal"
    Teams that deploy frequently (multiple times per day) are not reckless — they have reduced the cost and risk of each deployment so much that frequent deployment becomes the safest option. High deployment frequency and low change failure rate are not in tension. They correlate positively. Fast flow, done right, is also reliable flow.

---

## The Second Way: Feedback

Flow creates speed. Speed without feedback creates disasters.

The Second Way is about amplifying feedback loops at every stage of the delivery pipeline — so that problems are discovered as close as possible to where they are introduced.

The economics here are straightforward and brutal: the cost of fixing a bug grows exponentially with distance from its origin. A type error caught by a linter before a commit is a five-second fix. The same error caught in a code review is a five-minute fix. Caught in QA, it is a five-hour fix. Caught in production at 2am on a Saturday, with users affected, it is a five-day incident with a postmortem attached.

Shifting checks left — earlier in the pipeline — is not a process preference. It is cost reduction.

**Observability** is the production half of feedback. Logs, metrics, and traces are not nice-to-haves; they are the instruments that tell you whether what you shipped actually works the way you believe it does. The absence of observability is not "we have nothing to monitor" — it is "we are flying blind and will only discover problems from user complaints."

A useful question to ask before any deployment: *how will we know if this change is causing harm?* If the answer is "we will wait and see," the feedback loop is broken.

**Blameless postmortems** are where feedback becomes learning rather than punishment. When an incident is treated as evidence of a systemic failure rather than individual incompetence, people are willing to report problems, share context, and engage honestly with what went wrong. Blame, by contrast, drives problems underground — where they accumulate until the next, larger incident.

The Second Way asks: how quickly does the system tell you something is wrong, and how honestly can the team discuss it?

!!! note "Feedback is bidirectional"
    Feedback flows toward developers (tests, monitoring, postmortems) but also toward users and product teams. A feature shipped with instrumentation that measures adoption and impact closes the loop on whether the right thing was built. Without that loop, teams optimise delivery of the wrong things faster and faster.

---

## The Third Way: Continual Learning and Experimentation

The First Way optimises the path. The Second Way makes the path honest. The Third Way ensures the organisation gets better at walking it.

Continual learning means treating every failure as an opportunity to improve the system, not an anomaly to suppress. Every postmortem produces improvements to tooling, process, or documentation. Every near-miss is investigated before it becomes an incident. The system grows more reliable not because nothing goes wrong, but because the organisation learns faster than problems accumulate.

**Psychological safety** is the precondition for this to work. If surfacing a problem risks blame, people will hide problems. If admitting uncertainty risks appearing incompetent, people will fake confidence. An organisation that punishes honesty gets dishonesty — and operational brittleness.

**Experimentation** is the active form of learning. Rather than optimising a fixed process, high-performing teams question the process itself: what would happen if we removed this approval gate? What if we deployed on Fridays? What if on-call rotation included developers? The willingness to run controlled experiments — and to accept the results — is what separates teams that improve from teams that stagnate.

**Chaos engineering** is experimentation taken to its logical conclusion in infrastructure: deliberately introducing failures in production-like environments to find resilience gaps before they find you. The organisations that practice this — Netflix, Google, Amazon — are not reckless. They have concluded that the alternative (discovering failures during real incidents, without preparation) is more dangerous.

**Knowledge sharing** breaks down the silos that make teams fragile. When only one person understands a critical system, every deployment of that system is a risk. Documentation, pair work, runbooks, and internal tech talks distribute knowledge so that the bus factor — the number of people who would have to leave before the system becomes unmaintainable — is never one.

The Third Way asks: is this organisation more capable of delivering reliably next quarter than it is today?

---

## How The Three Ways Relate

The three ways are not sequential phases. They operate simultaneously and reinforce each other:

- **Flow** without **Feedback** is speed without a steering wheel.
- **Feedback** without **Flow** is a well-instrumented system that is still slow to change.
- **Learning** without **Flow** or **Feedback** is theory without grounding.

And crucially: none of the three are primarily about tools. A team can have world-class CI/CD infrastructure and still have broken flow if there are too many approval gates. A team can have comprehensive monitoring and still ignore what it says if the culture punishes the messenger. A team can run postmortems and still not improve if the action items are never completed.

The tools matter. But they amplify culture. They do not replace it.

---

## Why This Framing Matters

The Three Ways reframe DevOps from a set of tools and roles into a *way of thinking about delivery systems*. That framing is durable in a way that tool recommendations are not.

Terraform will be replaced by something else. Kubernetes will evolve past recognition. The principle that you should optimise for flow, amplify feedback, and build a learning organisation — that holds regardless of what the toolchain looks like in five years.

Starting from principles means that when a new tool or practice appears, you have a framework for evaluating it: does this improve flow? Does it shorten feedback loops? Does it help the team learn? If yes, it is worth examining. If it only adds complexity without advancing one of the three ways, it is worth skipping.

The question is never "should we adopt this tool?" It is always "what problem are we actually trying to solve, and is this the right way to solve it?"
