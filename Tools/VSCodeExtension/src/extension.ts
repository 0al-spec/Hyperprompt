// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as path from 'path';
import * as vscode from 'vscode';
import { RpcClient } from './rpcClient';

type ResolutionMode = 'strict' | 'lenient';
type LogLevel = 'error' | 'warn' | 'info' | 'debug';

type HyperpromptSettings = {
	resolutionMode: ResolutionMode;
	previewAutoUpdate: boolean;
	diagnosticsEnabled: boolean;
	enginePath: string;
	engineLogLevel: LogLevel;
};

const resolutionModes = new Set<ResolutionMode>(['strict', 'lenient']);
const logLevels = new Set<LogLevel>(['error', 'warn', 'info', 'debug']);

const normalizeEnumSetting = <T extends string>(value: string | undefined, allowed: Set<T>, fallback: T): T => {
	if (value && allowed.has(value as T)) {
		return value as T;
	}
	return fallback;
};

const readSettings = (): HyperpromptSettings => {
	const config = vscode.workspace.getConfiguration('hyperprompt');
	const resolutionMode = normalizeEnumSetting(
		config.get<string>('resolutionMode'),
		resolutionModes,
		'strict'
	);
	const previewAutoUpdate = config.get<boolean>('previewAutoUpdate', true);
	const diagnosticsEnabled = config.get<boolean>('diagnosticsEnabled', true);
	const enginePath = (config.get<string>('enginePath') ?? '').trim();
	const engineLogLevel = normalizeEnumSetting(
		config.get<string>('engineLogLevel'),
		logLevels,
		'info'
	);

	return {
		resolutionMode,
		previewAutoUpdate,
		diagnosticsEnabled,
		enginePath,
		engineLogLevel
	};
};

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Hyperprompt extension activated.');
	const compileTimeoutMs = 5000;
	let settings = readSettings();

	const buildRpcClient = (currentSettings: HyperpromptSettings): RpcClient => {
		const command = currentSettings.enginePath.length > 0 ? currentSettings.enginePath : 'hyperprompt';
		const env = {
			...process.env,
			HYPERPROMPT_LOG_LEVEL: currentSettings.engineLogLevel
		};

		return new RpcClient({
			command,
			args: ['editor-rpc'],
			env,
			onExit: () => {
				setTimeout(() => {
					rpcClient.start();
				}, 1000);
			}
		});
	};

	let rpcClient = buildRpcClient(settings);

	const restartRpcClient = (nextSettings: HyperpromptSettings) => {
		rpcClient.stop();
		rpcClient = buildRpcClient(nextSettings);
		rpcClient.start();
	};

	rpcClient.start();

	const getActiveEntryFile = (actionLabel: string): string | null => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showWarningMessage(`Hyperprompt: open a .hc file to ${actionLabel}.`);
			return null;
		}
		const entryFile = editor.document.uri.fsPath;
		if (path.extname(entryFile).toLowerCase() !== '.hc') {
			vscode.window.showWarningMessage(`Hyperprompt: open a .hc file to ${actionLabel}.`);
			return null;
		}
		return entryFile;
	};

	const runCompile = async (mode?: ResolutionMode) => {
		const entryFile = getActiveEntryFile('compile');
		if (!entryFile) {
			return null;
		}
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? path.dirname(entryFile);
		const resolvedMode = mode ?? settings.resolutionMode;
		const params = { entryFile, workspaceRoot, includeOutput: false, mode: resolvedMode };

		const result = await rpcClient.request('editor.compile', params, compileTimeoutMs);
		return result as { output?: string; diagnostics?: unknown[]; hasErrors?: boolean };
	};

	const compileCommand = vscode.commands.registerCommand('hyperprompt.compile', async () => {
		try {
			const compileResult = await runCompile();
			if (!compileResult) {
				return;
			}
			if (compileResult.hasErrors) {
				const count = compileResult.diagnostics?.length ?? 0;
				vscode.window.showErrorMessage(`Hyperprompt: compile reported ${count} diagnostics.`);
			} else {
				vscode.window.showInformationMessage('Hyperprompt: compile complete.');
			}
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: compile failed (${String(error)})`);
		}
	});

	const compileLenientCommand = vscode.commands.registerCommand('hyperprompt.compileLenient', async () => {
		try {
			const compileResult = await runCompile('lenient');
			if (!compileResult) {
				return;
			}
			if (compileResult.hasErrors) {
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
		try {
			const compileResult = await runCompile(settings.resolutionMode);
			if (!compileResult) {
				return;
			}
			vscode.window.showInformationMessage('Hyperprompt: preview is not wired yet.');
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: preview failed (${String(error)})`);
		}
	});

	const configWatcher = vscode.workspace.onDidChangeConfiguration((event) => {
		if (!event.affectsConfiguration('hyperprompt')) {
			return;
		}
		const nextSettings = readSettings();
		const engineChanged =
			nextSettings.enginePath !== settings.enginePath ||
			nextSettings.engineLogLevel !== settings.engineLogLevel;
		settings = nextSettings;
		if (engineChanged) {
			restartRpcClient(nextSettings);
		}
	});

	context.subscriptions.push(compileCommand, compileLenientCommand, previewCommand, configWatcher, rpcClient);
}

// This method is called when your extension is deactivated
export function deactivate() {}
