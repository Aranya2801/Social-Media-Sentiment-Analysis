# Contributing to SMSIP

Thank you for your interest in contributing! We welcome pull requests, bug reports, and feature suggestions.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/social-media-sentiment-intelligence.git
cd social-media-sentiment-intelligence
cp .env.example .env
make install
pre-commit install
```

## Development Workflow

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/your-feature-name`
3. **Write code** following our standards below
4. **Write tests** (aim for >80% coverage on new code)
5. **Run quality checks**: `make lint && make test`
6. **Commit** with a conventional commit message
7. **Push** and open a Pull Request

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(nlp): add multilingual sentiment support
fix(api): handle empty text input gracefully
docs(readme): update quick start instructions
test(forecast): add LSTM edge case tests
refactor(pipeline): extract model loading logic
perf(cache): reduce Redis key size by 40%
```

## Code Standards

### Python
- **Formatter**: Black (line length 100)
- **Linter**: Ruff
- **Type hints**: Required on all public functions
- **Docstrings**: Google style for public APIs
- **Tests**: pytest with >80% coverage

```python
async def analyze_text(
    text: str,
    tasks: Optional[List[str]] = None,
) -> AnalysisResult:
    """
    Analyze a single text with the NLP pipeline.

    Args:
        text: Raw input text (max 10,000 chars)
        tasks: Subset of tasks to run. Defaults to all.

    Returns:
        AnalysisResult with all model outputs.

    Raises:
        ValueError: If text is empty or exceeds max length.
    """
    ...
```

### TypeScript/React
- **Formatter**: Prettier
- **Linter**: ESLint (Next.js config)
- **Types**: Strict TypeScript, no `any`
- **Components**: Functional only, no class components
- **State**: Zustand for global, useState for local

## Pull Request Requirements

- [ ] Tests pass: `make test`
- [ ] Linting passes: `make lint`
- [ ] Coverage maintained or improved
- [ ] Documentation updated if API changes
- [ ] PR description explains the change and motivation
- [ ] Screenshots for UI changes

## Adding a New NLP Model

1. Create `backend/services/nlp/models/your_model.py`
2. Follow the pattern in `sentiment.py` — implement `predict()` and `_fallback_result()`
3. Register in `backend/services/nlp/pipeline.py`
4. Add to `backend/services/nlp/model_loader.py`
5. Add unit tests in `tests/unit/test_your_model.py`
6. Update `docs/architecture/SYSTEM_DESIGN.md`

## Reporting Issues

Use GitHub Issues with the appropriate template:
- 🐛 **Bug Report** — Something isn't working
- 💡 **Feature Request** — New capability suggestion
- 📊 **Model Performance** — Model accuracy issue
- 📚 **Documentation** — Docs improvement

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). We are committed to a welcoming, inclusive community.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
