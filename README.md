# Conventional Commits Git Hook

This tool helps you follow the [Conventional Commits](https://www.conventionalcommits.org) conventional by installing a configurable `commit-msg` into your Git projects.

### Installing

```sh
curl -o- https://raw.githubusercontent.com/chriscarrollsmith/conventional-commits-git-hook/master/scripts/install.sh | sh
```

In Windows, you can run this command in a "Git Bash" terminal. 

### Uninstalling

Remove the `commit-msg` Git hook from your project:

```sh
rm <your-project>/.git/hooks/commit-msg
```

## Usage <a name = "usage"></a>

Once installed, you must run `git init` in your Git projects to (re)initialize your repository.

**Supported types:**

```json
["build", "docs", "feat", "fix", "perf", "refactor", "style", "test", "chore"]
```

**Note**: you can disable this hook per commit by using `--no-verify`. Which is not recommended.

## IDE Plugins

- [JetBrains Conventional Commit](https://plugins.jetbrains.com/plugin/13389-conventional-commit)
- [VS Code Conventional Commit](https://marketplace.visualstudio.com/items?itemName=vivaxy.vscode-conventional-commits)
