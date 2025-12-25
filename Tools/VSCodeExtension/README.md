# hyperprompt README

This is the README for your extension "hyperprompt". After writing up a brief description, we recommend including the following sections.

## Features

Describe specific features of your extension including screenshots of your extension in action. Image paths are relative to this README file.

For example if there is an image subfolder under your extension project workspace:

\!\[feature X\]\(images/feature-x.png\)

> Tip: Many popular extensions utilize animations. This is an excellent way to show off your extension! We recommend short, focused animations that are easy to follow.

## Requirements

If you have any requirements or dependencies, add a section describing those and how to install and configure them.

## Development Testing

Run the extension in VS Code's Extension Development Host.

### CLI launch (requires `code` on PATH)

```bash
cd Tools/VSCodeExtension
npm run compile
code --extensionDevelopmentPath="$PWD"
```

In the Extension Development Host:
- Open any `.hc` file to trigger activation.
- Use Command Palette and run `Hyperprompt: Compile` or `Hyperprompt: Show Preview`.

If `code` is not found, install it from VS Code: Command Palette → "Shell Command: Install 'code' command in PATH".

### RPC Client Notes

The extension spawns the Hyperprompt CLI in RPC mode on activation. Build with the Editor trait enabled:

```bash
swift build --traits Editor
hyperprompt editor-rpc
```

If the CLI is missing from your PATH, install Hyperprompt and ensure `hyperprompt` is discoverable in your shell before launching the dev host.

### VS Code UI

1. Open `Tools/VSCodeExtension` in VS Code.
2. Press `F5` (Run Extension).
3. In the dev host, open a `.hc` file and run commands from the Command Palette.

## Extension Settings

Include if your extension adds any VS Code settings through the `contributes.configuration` extension point.

For example:

This extension contributes the following settings:

* `myExtension.enable`: Enable/disable this extension.
* `myExtension.thing`: Set to `blah` to do something.

## Known Issues

Calling out known issues can help limit users opening duplicate issues against your extension.

## Release Notes

Users appreciate release notes as you update your extension.

### 1.0.0

Initial release of ...

### 1.0.1

Fixed issue #.

### 1.1.0

Added features X, Y, and Z.

---

## Following extension guidelines

Ensure that you've read through the extensions guidelines and follow the best practices for creating your extension.

* [Extension Guidelines](https://code.visualstudio.com/api/references/extension-guidelines)

## Working with Markdown

You can author your README using Visual Studio Code. Here are some useful editor keyboard shortcuts:

* Split the editor (`Cmd+\` on macOS or `Ctrl+\` on Windows and Linux).
* Toggle preview (`Shift+Cmd+V` on macOS or `Shift+Ctrl+V` on Windows and Linux).
* Press `Ctrl+Space` (Windows, Linux, macOS) to see a list of Markdown snippets.

## For more information

* [Visual Studio Code's Markdown Support](http://code.visualstudio.com/docs/languages/markdown)
* [Markdown Syntax Reference](https://help.github.com/articles/markdown-basics/)

**Enjoy!**
