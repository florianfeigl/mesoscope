# AI Agent Configuration

This repository uses a centralized AI assistance system. For full documentation, configuration, and usage instructions, please refer to the central model-statistics repository.

## Central Repository
- GitHub: https://github.com/florianfeigl/model-statistics
- Contains: AI agent instructions, session logs, metrics, and best practices
- Documentation: See `ai-assistance.md` for detailed guidelines
- Model selection guide: See `docs/model-selection.md` and log `data/model-choice-events.csv`
- Tools and hooks: See `docs/tools.md` and `scripts/add-model-choice.py`; optional hooks in `githooks/`
- Local clone: `~/repos/model-statistics/` (recommended for faster access)

## Quick Start
1. For AI-assisted work, first check the model-statistics repository for existing patterns and documentation
2. Follow the established workflows and conventions
3. Document significant AI-assisted changes in the central repository

## Model Escalation Protocol

The agent MUST explicitly notify the user when a model escalation is recommended. Silent model changes are not permitted.

**Escalate and inform the user when:**
- The task involves multi-layer architecture decisions or complex system design
- The same error or misunderstanding recurs after 2 correction attempts
- The context exceeds ~50k tokens (large codebase analysis, many files simultaneously)
- The change is security- or production-critical (auth, firewall, live deployments)
- The task requires strategic planning or long-term roadmap reasoning
- The agent's own confidence is low or output appears uncertain/hallucinated

**Required escalation message format:**
```
> **Model Escalation Recommended**
> The current task exceeds the optimal scope of the active model.
> Reason: <brief reason, e.g. "multi-layer architecture decision" or "context >50k tokens">
> Recommendation: Switch to <target model, e.g. "Claude Opus" or "GPT-4o">
> Alternative: Split the task into smaller steps and continue with the current model.
> Please decide how you would like to proceed.
```

After issuing the notice, the agent pauses and waits for the user's decision before continuing.
See `~/repos/model-statistics/docs/model-selection.md` (section "Eskalations-Protokoll") for full criteria.

## Local Repository Notes
- This is a standard project repository with minimal AI configuration
- All AI assistance documentation is maintained centrally
- Check for repository-specific notes in the model-statistics sessions directory