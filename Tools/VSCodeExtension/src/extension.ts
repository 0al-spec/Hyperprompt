// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as path from 'path';
import * as vscode from 'vscode';
import { RpcClient } from './rpcClient';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Hyperprompt extension activated.');
	const compileTimeoutMs = 60000;

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
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showWarningMessage('Hyperprompt: open a .hc file to compile.');
			return;
		}
		const entryFile = editor.document.uri.fsPath;
		if (path.extname(entryFile).toLowerCase() !== '.hc') {
			vscode.window.showWarningMessage('Hyperprompt: open a .hc file to compile.');
			return;
		}
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

		try {
			const result = await rpcClient.request(
				'editor.compile',
				{ entryFile, workspaceRoot },
				compileTimeoutMs
			);
			const compileResult = result as { output?: string; diagnostics?: unknown[]; hasErrors?: boolean };
			if (compileResult?.hasErrors) {
				const count = compileResult.diagnostics?.length ?? 0;
				vscode.window.showErrorMessage(`Hyperprompt: compile reported ${count} diagnostics.`);
			} else {
				vscode.window.showInformationMessage('Hyperprompt: compile complete.');
			}
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: compile failed (${String(error)})`);
		}
	});

	const previewCommand = vscode.commands.registerCommand('hyperprompt.showPreview', async () => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showWarningMessage('Hyperprompt: open a .hc file to show preview.');
			return;
		}
		const entryFile = editor.document.uri.fsPath;
		if (path.extname(entryFile).toLowerCase() !== '.hc') {
			vscode.window.showWarningMessage('Hyperprompt: open a .hc file to show preview.');
			return;
		}
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

		try {
			await rpcClient.request(
				'editor.compile',
				{ entryFile, workspaceRoot },
				compileTimeoutMs
			);
			vscode.window.showInformationMessage('Hyperprompt: preview is not wired yet.');
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: preview failed (${String(error)})`);
		}
	});

	context.subscriptions.push(compileCommand, previewCommand, rpcClient);
}

// This method is called when your extension is deactivated
export function deactivate() {}
