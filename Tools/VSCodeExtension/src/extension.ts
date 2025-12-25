// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { RpcClient } from './rpcClient';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Hyperprompt extension activated.');
	const indexTimeoutMs = 30000;

	const rpcClient = new RpcClient({
		command: 'hyperprompt',
		args: ['editor-rpc'],
		onExit: () => {
			setTimeout(() => {
				rpcClient.start();
			}, 1000);
		}
	});

	rpcClient.start();

	const compileCommand = vscode.commands.registerCommand('hyperprompt.compile', async () => {
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
		if (!workspaceRoot) {
			vscode.window.showWarningMessage('Hyperprompt: open a workspace to compile.');
			return;
		}

		try {
			await rpcClient.request('editor.indexProject', { workspaceRoot }, indexTimeoutMs);
			vscode.window.showInformationMessage('Hyperprompt: index complete.');
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: compile failed (${String(error)})`);
		}
	});

	const previewCommand = vscode.commands.registerCommand('hyperprompt.showPreview', async () => {
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
		if (!workspaceRoot) {
			vscode.window.showWarningMessage('Hyperprompt: open a workspace to show preview.');
			return;
		}

		try {
			await rpcClient.request('editor.indexProject', { workspaceRoot }, indexTimeoutMs);
			vscode.window.showInformationMessage('Hyperprompt: preview is not wired yet.');
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: preview failed (${String(error)})`);
		}
	});

	context.subscriptions.push(compileCommand, previewCommand, rpcClient);
}

// This method is called when your extension is deactivated
export function deactivate() {}
