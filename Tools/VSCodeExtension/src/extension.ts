// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as path from 'path';
import * as vscode from 'vscode';
import { buildCompileParams, runCompileRequest, ResolutionMode } from './compileCommand';
import { resolveEngine, engineDiscoveryDefaults, EngineResolution } from './engineDiscovery';
import {
	buildLinkAtParams,
	buildResolveParams,
	describeResolvedTarget,
	resolvedTargetPath,
	runLinkAtRequest,
	runResolveRequest
} from './navigation';
import { RpcClient } from './rpcClient';
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
export async function activate(context: vscode.ExtensionContext) {
	console.log('Hyperprompt extension activated.');
	const compileTimeoutMs = 5000;
	const outputChannel = vscode.window.createOutputChannel('Hyperprompt');
	let settings = readSettings();
	let rpcClient: RpcClient | null = null;
	let engineResolution: EngineResolution | null = null;
	let lastEngineErrorMessage: string | null = null;
	let refreshInFlight: Promise<void> | null = null;

	const stopRpcClient = () => {
		if (!rpcClient) {
			return;
		}
		const client = rpcClient;
		rpcClient = null;
		client.stop();
	};

	const notifyEngineError = (message: string) => {
		if (message.length === 0 || message === lastEngineErrorMessage) {
			return;
		}
		lastEngineErrorMessage = message;
		vscode.window.showErrorMessage(message);
	};

	const buildRpcClient = (command: string, logLevel: LogLevel): RpcClient => {
		const env = {
			...process.env,
			HYPERPROMPT_LOG_LEVEL: logLevel
		};
		const client = new RpcClient({
			command,
			args: ['editor-rpc'],
			env,
			onExit: () => {
				if (rpcClient !== client) {
					return;
				}
				setTimeout(() => {
					if (rpcClient === client) {
						client.start();
					}
				}, 1000);
			}
		});
		return client;
	};

	const refreshEngineState = async (showErrors: boolean) => {
		if (refreshInFlight) {
			await refreshInFlight;
			return;
		}
		refreshInFlight = (async () => {
			const env = {
				...process.env,
				HYPERPROMPT_LOG_LEVEL: settings.engineLogLevel
			};
			const resolution = await resolveEngine({
				platform: process.platform,
				enginePath: settings.enginePath,
				extensionPath: context.extensionPath,
				env,
				bundledRelativePath: engineDiscoveryDefaults.bundledRelativePath
			});
			engineResolution = resolution;

			if (!resolution.ok) {
				stopRpcClient();
				if (showErrors) {
					notifyEngineError(resolution.message);
				}
				return;
			}

			lastEngineErrorMessage = null;
			stopRpcClient();
			const client = buildRpcClient(resolution.command, settings.engineLogLevel);
			rpcClient = client;
			client.start();
		})();
		await refreshInFlight;
		refreshInFlight = null;
	};

	const ensureEngineReady = async (): Promise<RpcClient | null> => {
		if (engineResolution?.ok && rpcClient) {
			return rpcClient;
		}
		await refreshEngineState(true);
		if (engineResolution?.ok && rpcClient) {
			return rpcClient;
		}
		if (engineResolution && !engineResolution.ok) {
			notifyEngineError(engineResolution.message);
		}
		return null;
	};

	void refreshEngineState(true);

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

	const renderCompileOutput = (result: { output?: string }) => {
		if (result.output && result.output.length > 0) {
			outputChannel.clear();
			outputChannel.appendLine(result.output);
			outputChannel.show(true);
			return;
		}
		vscode.window.showWarningMessage('Hyperprompt: compile produced no output.');
	};

	const runCompile = async (mode: ResolutionMode, includeOutput: boolean) => {
		const entryFile = getActiveEntryFile('compile');
		if (!entryFile) {
			return null;
		}
		const client = await ensureEngineReady();
		if (!client) {
			return null;
		}
		const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
		const params = buildCompileParams(entryFile, workspaceRoot, mode, includeOutput);
		return runCompileRequest(client.request.bind(client), params, compileTimeoutMs);
	};

	const compileCommand = vscode.commands.registerCommand('hyperprompt.compile', async () => {
		try {
			const compileResult = await runCompile(settings.resolutionMode, true);
			if (!compileResult) {
				return;
			}
			if (compileResult.hasErrors) {
				const count = compileResult.diagnostics?.length ?? 0;
				vscode.window.showErrorMessage(`Hyperprompt: compile reported ${count} diagnostics.`);
			} else {
				vscode.window.showInformationMessage('Hyperprompt: compile complete.');
			}
			renderCompileOutput(compileResult);
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: compile failed (${String(error)})`);
		}
	});

	const compileLenientCommand = vscode.commands.registerCommand('hyperprompt.compileLenient', async () => {
		try {
			const compileResult = await runCompile('lenient', true);
			if (!compileResult) {
				return;
			}
			if (compileResult.hasErrors) {
				const count = compileResult.diagnostics?.length ?? 0;
				vscode.window.showErrorMessage(`Hyperprompt: compile reported ${count} diagnostics.`);
			} else {
				vscode.window.showInformationMessage('Hyperprompt: compile complete.');
			}
			renderCompileOutput(compileResult);
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: compile failed (${String(error)})`);
		}
	});

	const previewCommand = vscode.commands.registerCommand('hyperprompt.showPreview', async () => {
		try {
			const compileResult = await runCompile(settings.resolutionMode, false);
			if (!compileResult) {
				return;
			}
			vscode.window.showInformationMessage('Hyperprompt: preview is not wired yet.');
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: preview failed (${String(error)})`);
		}
	});

	const resolveWorkspaceRoot = (document: vscode.TextDocument): string => {
		const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
		return workspaceFolder?.uri.fsPath ?? path.dirname(document.uri.fsPath);
	};

	const definitionProvider = vscode.languages.registerDefinitionProvider('hypercode', {
		provideDefinition: async (document, position) => {
			if (path.extname(document.uri.fsPath).toLowerCase() !== '.hc') {
				return null;
			}
			try {
				const client = await ensureEngineReady();
				if (!client) {
					return null;
				}
				const linkParams = buildLinkAtParams(
					document.uri.fsPath,
					position.line,
					position.character
				);
				const linkSpan = await runLinkAtRequest(
					client.request.bind(client),
					linkParams,
					compileTimeoutMs
				);
				if (!linkSpan) {
					return null;
				}
				const resolveParams = buildResolveParams(
					linkSpan.literal,
					linkSpan.sourceFile,
					resolveWorkspaceRoot(document)
				);
				const target = await runResolveRequest(
					client.request.bind(client),
					resolveParams,
					compileTimeoutMs
				);
				const targetPath = resolvedTargetPath(target);
				if (!targetPath) {
					return null;
				}
				return new vscode.Location(vscode.Uri.file(targetPath), new vscode.Position(0, 0));
			} catch (error) {
				console.error(`[hyperprompt] definition failed: ${String(error)}`);
				return null;
			}
		}
	});

	const hoverProvider = vscode.languages.registerHoverProvider('hypercode', {
		provideHover: async (document, position) => {
			if (path.extname(document.uri.fsPath).toLowerCase() !== '.hc') {
				return null;
			}
			try {
				const client = await ensureEngineReady();
				if (!client) {
					return null;
				}
				const linkParams = buildLinkAtParams(
					document.uri.fsPath,
					position.line,
					position.character
				);
				const linkSpan = await runLinkAtRequest(
					client.request.bind(client),
					linkParams,
					compileTimeoutMs
				);
				if (!linkSpan) {
					return null;
				}
				const resolveParams = buildResolveParams(
					linkSpan.literal,
					linkSpan.sourceFile,
					resolveWorkspaceRoot(document)
				);
				const target = await runResolveRequest(
					client.request.bind(client),
					resolveParams,
					compileTimeoutMs
				);
				const markdown = new vscode.MarkdownString(
					[`**Hyperprompt**`, `Link: \`${linkSpan.literal}\``, describeResolvedTarget(target)].join('\n\n')
				);
				return new vscode.Hover(markdown);
			} catch (error) {
				console.error(`[hyperprompt] hover failed: ${String(error)}`);
				return null;
			}
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
			void refreshEngineState(true);
		}
	});

	context.subscriptions.push(
		compileCommand,
		compileLenientCommand,
		previewCommand,
		definitionProvider,
		hoverProvider,
		configWatcher,
		outputChannel,
		{ dispose: () => stopRpcClient() }
	);
}

// This method is called when your extension is deactivated
export function deactivate() {}
