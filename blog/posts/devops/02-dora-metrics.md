---
date: 2026-04-28
title: DORA Metrics — How to Know If DevOps Is Actually Working
---

The previous post ended with a claim: DevOps is not primarily about tools, it is about principles. The Three Ways — Flow, Feedback, Continual Learning — are the right lens for thinking about delivery systems.

That claim raises an obvious question: how do you know if it is working?

You need numbers. Specifically, you need numbers that measure the *outcomes* of your delivery system, not the activities inside it. Counting pull requests merged, pipelines run, or deployments attempted tells you how busy a team is. It does not tell you how effective it is.

DORA — the DevOps Research and Assessment team at Google — spent seven years studying thousands of engineering teams to find the metrics that actually predict high performance. They landed on four.

---

## The Four Metrics

The four DORA metrics split cleanly into two dimensions.

### Throughput

**Deployment Frequency** measures how often your team ships to production. Daily, weekly, monthly, quarterly?

**Lead Time for Changes** measures how long it takes a committed change to reach production. From the moment a developer pushes code to the moment a user can see it — minutes, hours, days, weeks?

These two metrics measure **The First Way: Flow**. They answer: how fast can the system move?

### Stability

**Change Failure Rate** measures what fraction of deployments cause a degradation or outage requiring a fix, rollback, or hotfix. 5%? 30%?

**Time to Restore Service** measures how long it takes to recover when something does go wrong. Minutes, hours, days?

These two metrics measure **The Second Way: Feedback** and resilience. They answer: when the system moves fast, how safely does it do so?

---

## The Finding That Changes the Conversation

The most important thing DORA's research produced is not the metrics themselves. It is what the data showed when they measured elite teams against low performers.

The conventional assumption in engineering organisations is that speed and stability trade off against each other. Ship faster, break more things. Be more careful, ship slower. This assumption is the foundation of change advisory boards, week-long testing cycles, and deployment windows that open once a month.

**The data says the opposite.**

Elite performers — the top tier of the teams DORA studied — deploy *more* frequently *and* have *lower* change failure rates *and* restore service *faster* than low performers. All four metrics move in the same direction. Speed and stability are not in tension. They are, empirically, the same thing achieved by the same practices.

| | Elite | Low |
| --- | --- | --- |
| Deployment Frequency | On-demand, multiple times per day | Fewer than once per month |
| Lead Time for Changes | Less than one hour | One to six months |
| Change Failure Rate | 0–15% | 46–60% |
| Time to Restore Service | Less than one hour | One week to one month |

The difference between elite and low is not marginal. It is an order of magnitude in every direction.

The implication is uncomfortable: if your team has a high change failure rate, the answer is almost certainly not to deploy less often. It is to make individual deployments smaller, make them easier to roll back, and invest in the feedback mechanisms that catch failures faster. Slowing down to "be more careful" is the instinct that keeps teams in the low-performer quadrant.

!!! note "Why this is counterintuitive"
    Large, infrequent deployments feel safer. They are planned, reviewed, scheduled. But they are larger, so when they fail, more things are broken at once. They are infrequent, so the team is less practiced at the deployment process. They are harder to roll back because the diff is enormous. Small, frequent deployments are less dramatic but empirically more reliable.

---

## Two by Two

The two dimensions — throughput and stability — produce a useful diagnostic grid.

**High throughput, high stability** is where elite teams operate. The First and Second Ways are working.

**High throughput, low stability** is the "move fast and break things" failure mode. The team has optimised for speed but has weak feedback loops. Observability is poor, tests are flimsy, and the team discovers failures from user complaints rather than dashboards.

**Low throughput, high stability** is the cautious-but-slow failure mode. Heavy process — long review cycles, change approval gates, manual testing — has reduced failure rate but at the cost of lead time. The team feels safe but is spending that safety budget on the wrong thing.

**Low throughput, low stability** is where teams end up when neither Way is working. Long release cycles that still fail frequently. This is usually where the "we need to stabilise before we can go faster" conversation happens — the conversation that, without structural change, produces more of the same.

---

## How to Use These Metrics Well

A measurement that becomes a target stops being a useful measurement. Goodhart's Law applies here exactly.

If a team is told their deployment frequency is being tracked and used to evaluate performance, they will find ways to increase deployment frequency — splitting changes artificially, creating trivial deployments, gaming the definition of "production." The metric goes up. The underlying system does not improve.

DORA metrics work when they are used **diagnostically**, not as scorecards.

The right questions:
- Why is our lead time measured in days when the actual work takes hours? Where is the waiting happening?
- Our change failure rate is 40%. What does a failing change look like? Is it always the same type of change?
- We can deploy, but restoring service takes four hours. What makes recovery slow — detection, diagnosis, or the rollback process itself?

Each metric points toward a class of problems. Deployment frequency and lead time point toward friction in the delivery pipeline — approval gates, slow CI, manual steps. Change failure rate points toward test coverage and the quality of pre-production validation. Time to restore points toward observability, runbook quality, and on-call process.

!!! warning "Don't compare teams"
    DORA metrics measure a team's delivery *system*, not the team's effort or skill. Two teams working on different parts of a system may have structurally different deployment profiles — not because one team is better, but because one codebase has more external dependencies, more compliance requirements, or a longer test suite. Comparing metrics across teams without understanding the structural differences produces unfair evaluations and perverse incentives.

---

## What the Metrics Cannot Tell You

DORA metrics measure how well software is delivered. They do not measure whether the right software is being delivered.

A team can have elite DORA metrics — deploying dozens of times a day, sub-hour lead times, near-zero change failure rate — and still be building features that users do not want or that do not move business outcomes.

The Third Way — Continual Learning — is where this gap closes. DORA metrics are a lagging indicator of delivery system health. The leading indicators are things like: does the team have observability into whether new features are used? Do deployments include instrumentation that measures user behaviour, not just system health? Does the team have a feedback loop from users back to the backlog?

The metrics tell you how fast the car is going and whether the engine is running smoothly. They do not tell you whether you are driving in the right direction.

---

## Starting Point

Most teams do not have DORA metrics instrumented from day one. Starting can feel like a large project.

It does not need to be. A useful first pass:

1. **Lead time**: pick one recent change and trace it manually — when was the first commit, when did it reach production? Repeat for ten changes. The variance is usually more informative than the average.
2. **Deployment frequency**: count production deployments over the last 30 days. Is the answer surprising?
3. **Change failure rate**: of those deployments, how many required a rollback or a follow-up fix within 24 hours?
4. **Time to restore**: pick the last three incidents. How long from "first alert or complaint" to "service restored"?

The numbers do not need to be precise on the first pass. They need to be honest. An honest number that surprises the team is far more valuable than a precise number that confirms what everyone already believed.

That surprise — the gap between what the team thought the system was doing and what it is actually doing — is where improvement starts.
