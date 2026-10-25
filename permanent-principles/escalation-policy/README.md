# Rationale

Models are inclined to follow instructions too literally, and to keep going into the instructed direction even when it doesn't make sense. This escalation policy gives models permission to recognize when something likely doesn't make sense, and to pause and raise such issues with the user.

# Usage

Preferred: paste the contents directly into AGENTS.md.

If that's not possible, then the next best thing is to paste a reference instruction in AGENTS.md:

```markdown
Before starting any task, including planning, read and apply these documents (unless already in context) in full using a file-reading tool:

- `path-to/escalation-policy.md` - This policy governs how to pursue the user's underlying goal rather than merely comply literally. Defines when to pause and discuss material issues with the user and when to proceed autonomously, so you need it before choosing an approach. Read it upfront even if the task seems straightforward or you think you already know the policy; this summary is not a substitute.
```
