# Starting backend server
```
uv run python3 main.py 
```

# Pushing code to production
Before pushing code to production, make sure to run the following command for static type checking:
```
uv run mypy .
```
If you added new dependencies, remember to run before pushing:
```
uv sync
```

# Depemdencies
You can add new dependencies to the project using:
```
uv add <package-name>
```

