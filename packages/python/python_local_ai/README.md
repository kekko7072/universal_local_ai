# python_local_ai

Final monorepo path for the `python_local_ai` PyPI package. Until its history
is imported, the source lives in
[`kekko7072/python_local_ai`](https://github.com/kekko7072/python_local_ai),
linked here as the top-level `python_local_ai/` submodule.

It is a set of PyO3 bindings over `rust_local_ai`, with an asyncio and a
blocking API:

```python
import python_local_ai as lai

model = lai.detect()
if model.availability_sync():
    with model.open_session_sync("Be brief.") as session:
        print(session.generate_sync("Hello!").text)
```

Not yet published to PyPI.
