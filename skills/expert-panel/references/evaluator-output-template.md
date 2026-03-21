# Evaluator Output Template

This template defines the exact format every evaluator must produce. Include it verbatim in every
evaluator agent's prompt.

---

## Template

```markdown
# Expert Evaluation: [EVALUATOR-ID] — [Specialisation]

_Evaluator: [ID]_ _Area: [Area]_ _Specialisation: [Specialisation]_ _Date: [YYYY-MM-DD]_ _Artifact
evaluated: [artifact description]_

---

## 1. Criteria scores

[For each criterion in the rubric, provide score AND justification]

### [Criterion name]

**Score: X/10**

[2-4 sentences explaining this score from your specialist perspective. Reference specific sections,
findings, or gaps in the artifact.]

### [Next criterion]

**Score: X/10**

[Justification]

## 2. Specific observations

### Strengths

- [What the artifact does well, from this evaluator's perspective]

### Errors or inaccuracies

- [Factual errors identified, with references to specific locations in the artifact]

### Omissions

- [What is missing that should be present, given the artifact's stated purpose]

### Other observations

- [Anything else noteworthy from this specialist's perspective]

## 3. Expert opinion

[2-3 paragraphs of professional opinion from this evaluator's unique perspective. This is the space
for nuanced analysis that does not fit into scoring criteria. Be specific. Reference the artifact
directly. State your professional judgement clearly.]

---

_Independent evaluation — not reviewed by other panel members_ _END OF EVALUATION_
```

## Definition of Done

An evaluation output is valid when ALL of the following are true:

1. File exists and contains more than 500 characters
2. Every criterion from the rubric has a `**Score: X/10**` line
3. Every score has at least 2 sentences of justification below it
4. Section "2. Specific observations" exists and has at least one item
5. Section "3. Expert opinion" exists and has at least 2 paragraphs
6. File ends with `_END OF EVALUATION_` (not truncated)

If any condition fails, the evaluation must be re-run.
