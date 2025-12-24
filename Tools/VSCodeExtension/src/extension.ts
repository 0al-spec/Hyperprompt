// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Hyperprompt extension activated.');

	const compileCommand = vscode.commands.registerCommand('hyperprompt.compile', () => {
		vscode.window.showInformationMessage('Hyperprompt: compile is not wired yet.');
	});

	const previewCommand = vscode.commands.registerCommand('hyperprompt.showPreview', () => {
		vscode.window.showInformationMessage('Hyperprompt: preview is not wired yet.');
	});

	context.subscriptions.push(compileCommand, previewCommand);
}

// This method is called when your extension is deactivated
export function deactivate() {}
