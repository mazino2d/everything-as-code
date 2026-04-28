---
date: 2026-04-28
title: Blameless Postmortem — Learning From Failure Without Destroying Trust
---

The deployment went out at 16:23. By 16:31, the error rate was at 40%. By 16:35, the on-call engineer had rolled back. By 16:40, service was restored. Total customer impact: seventeen minutes.

In the post-incident meeting, someone asks: "who approved this change?"

That question — asked innocently, in the name of accountability — is where most organisations stop learning.

---

## Blame Is the Natural Response

When something breaks, humans look for a cause. And causes, in human psychology, are usually agents — people who did things. The engineer who wrote the code. The reviewer who approved it. The manager who pushed for the release. Finding the person feels like finding the answer.

It is not.

Blame is satisfying because it is simple. It converts a complex, systemic failure into a story with a villain. Once the villain is identified, the problem feels solved. The organisation moves on.

But the system that produced the failure has not changed. The conditions that made the failure possible — the gaps in testing, the missing rollback procedure, the deployment process that did not catch the issue — are still there. The next person to walk into those conditions will produce the same outcome.

This is why organisations that respond to incidents with blame have the same incidents repeatedly. Not because they keep hiring bad engineers. Because they keep treating symptoms instead of causes.

---

## What Blame Does to a Team

Beyond the systemic problem, blame has a second consequence: it changes what people are willing to say.

In a blame culture, engineers learn quickly that honesty is dangerous. Admitting you made a mistake means being the villain in the next post-incident meeting. Flagging a risk you noticed but did not escalate means being blamed for not acting on it. The rational response is to say less, document less, and surface problems only when they are impossible to ignore.

The result is an organisation that is systematically less informed about its own risks. Near-misses are not reported. Problems are hidden until they become incidents. When incidents do occur, the timeline is reconstructed from partial information because nobody wanted to leave a paper trail.

Psychological safety — the belief that raising a concern will not result in punishment — is the precondition for honest postmortems. It cannot be mandated by a process. It is built slowly by how an organisation responds to the first few incidents after committing to blameless culture, and destroyed instantly the moment someone is punished for honesty.

---

## There Is No Root Cause

The standard postmortem template asks: what was the root cause?

This is the wrong question for complex systems.

James Reason, a psychologist who spent decades studying industrial accidents, developed the Swiss cheese model: in complex systems, failures are never the result of a single cause. They are the result of multiple contributing factors that aligned at the wrong moment. Each factor alone is insufficient to produce failure — like a slice of Swiss cheese, it has holes, but not in the same place. When the holes in multiple slices line up, the failure occurs.

The implication is uncomfortable: in most incidents, any individual contributing factor could have been removed and the incident would not have happened. But so could any other factor. There is no single root cause. There are only conditions that, together, allowed failure to occur.

The practical consequence: postmortems that search for a root cause will find one — usually the most proximate human action. "The engineer deployed a change that introduced a bug." That is true. It is also useless. It tells you nothing about why the testing did not catch the bug, why the deployment process did not allow for early detection, why the rollback took eleven minutes instead of two, or why the alert fired seven minutes after the error rate first spiked.

Replacing "root cause" with "contributing factors" is not semantic softening. It is a more accurate model of how complex systems fail — and it produces a longer, more actionable list of things to fix.

!!! note "The last person to touch it"
    When you search for a root cause, you almost always find the last person who touched the system before it failed. This is not because that person caused the failure. It is because they were closest to it. Stopping the investigation there — "the root cause was the deployment" — means ignoring every systemic condition that made that deployment dangerous. The Swiss cheese model asks you to keep going until you have found every contributing slice.

---

## What Blameless Actually Means

Blameless does not mean consequence-free. This is the most common misunderstanding of the concept.

Sidney Dekker, whose work on human factors in accidents influenced much of modern incident culture, distinguishes between two types of accountability:

**Retributive accountability**: someone made a mistake, therefore they should be punished. The logic is moral — wrongdoing deserves consequences — but it produces no improvement to the system.

**Restorative accountability**: something went wrong, therefore the people involved should participate in understanding what happened and in fixing it. The logic is practical — the people closest to the failure have the most information about it.

A blameless postmortem holds the *system* accountable. It asks: what conditions made this failure possible? What should change so those conditions do not recur? It does not ask: who should we be angry at?

This matters because the engineers closest to an incident are the ones with the most detailed knowledge of what happened. If they fear punishment, they will not share that knowledge. Blameless culture is not about protecting engineers from consequences — it is about ensuring the organisation has access to the information it needs to improve.

---

## What a Postmortem That Actually Works Looks Like

Most postmortem templates produce documents that feel complete but produce no learning. The root cause field is filled with something vague. The action items are assigned to whoever was involved in the incident. Nobody follows up. The document is filed. Three months later, the same incident occurs.

A postmortem that produces improvement has five properties.

**An honest, specific timeline.** Not "around 3pm the service began degrading" — but "14:47:23: error rate crossed 1%. 14:52:11: alert fired. 14:53:40: on-call acknowledged. 14:59:00: first hypothesis tested and ruled out." Specific timestamps are not bureaucracy. They reveal where time was lost — the five minutes between the error spike and the alert, the seven minutes between acknowledgement and first action — and those gaps are where improvements live.

**Contributing factors, not root cause.** For each factor, ask why it was possible. The deployment introduced a bug — why did testing not catch it? The alert fired five minutes late — why was the threshold set there? The rollback took eleven minutes — why does the rollback procedure take that long? Keep asking why until you reach something that can actually be changed.

**A clear description of customer impact.** How many users were affected? What did they experience? For how long? This is not about assigning severity for blame — it is about calibrating the investment in prevention. A seventeen-minute impact to 0.3% of users warrants different action items than a four-hour outage affecting all users.

**Action items that are specific, assigned, and time-bounded.** "Improve monitoring" is not an action item. "Add an alert on malformed response bodies from the payments API with a threshold of >0.1% over five minutes, assigned to the platform team, due in two weeks" is an action item. Vague action items exist to make the postmortem look complete without committing to anything.

**A follow-up mechanism.** Action items that are never reviewed are not action items — they are wishful thinking. The postmortem is not finished when the document is written. It is finished when the action items are either completed or explicitly deprioritised with a documented reason.

!!! tip "Share postmortems widely"
    A postmortem read only by the people involved in the incident produces local learning. A postmortem shared with the broader engineering organisation — or posted publicly, as many companies do — produces distributed learning. Other teams recognise the same conditions in their own systems and act before an incident occurs. The investment in writing a good postmortem compounds when it is shared.

---

## The Failure Mode: Blameless in Name Only

Many organisations have adopted blameless postmortems as a label without adopting the underlying practice.

The signs:

- The postmortem template has a "root cause" field, and it is always filled with a technical artefact or a human action rather than a systemic condition.
- Action items are routinely assigned to whoever was on-call during the incident, not to the teams responsible for the systemic gaps the incident revealed.
- Postmortems are conducted, but nobody reads them outside of the immediate team.
- The same class of incident recurs on a six-to-twelve month cycle.
- Engineers are "blameless" in the postmortem document but still feel the career impact of being associated with a high-severity incident.

The last point is the most corrosive. If the postmortem process is blameless but the performance review process is not — if being the engineer on-call during a major incident affects promotion decisions — then the postmortem culture is a fiction. Engineers will participate in the form while protecting themselves from the substance.

Genuine blameless culture requires consistency across every process that touches engineer evaluation. Postmortems alone are not enough.

---

## The Learning Organisation

Return to the Three Ways. The Third Way — Continual Learning — is not a practice. It is an outcome. The practices are: honest postmortems, completed action items, shared knowledge, psychological safety, and a consistent signal from leadership that surfacing problems is valued over suppressing them.

The organisations that improve fastest are not the ones that have the fewest incidents. They are the ones that extract the most learning from every incident they do have.

Failure is inevitable in complex systems. The question is not how to eliminate it — it is how to ensure that every failure makes the system measurably more resilient than it was before.

A postmortem that produces two specific, completed improvements to the system is worth more than a hundred postmortem documents filed and forgotten.
