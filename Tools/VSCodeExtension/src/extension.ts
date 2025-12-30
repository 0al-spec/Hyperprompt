// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as path from 'path';
import * as vscode from 'vscode';
import { buildCompileParams, runCompileRequest, ResolutionMode } from './compileCommand';
import { RpcDiagnostic, normalizeSeverity, toZeroBasedRange } from './diagnostics';
import { resolveEngine, engineDiscoveryDefaults, EngineResolution } from './engineDiscovery';
import {
	buildLinkAtParams,
	buildResolveParams,
	describeResolvedTarget,
	resolvedTargetPath,
	runLinkAtRequest,
	runResolveRequest
} from './navigation';
import { buildPreviewHtml } from './preview';
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
	const diagnosticCollection = vscode.languages.createDiagnosticCollection('hyperprompt');
	let settings = readSettings();
	let rpcClient: RpcClient | null = null;
	let engineResolution: EngineResolution | null = null;
	let lastEngineErrorMessage: string | null = null;
	let refreshInFlight: Promise<void> | null = null;
	let previewPanel: vscode.WebviewPanel | null = null;
	let previewEntryFile: string | null = null;
	let previewSourceMap: import('./compileCommand').SourceMap | null = null;

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

	const getActiveHypercodeEditor = (): vscode.TextEditor | null => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showInformationMessage('Hyperprompt: No active editor.');
			return null;
		}
		const document = editor.document;
		if (path.extname(document.uri.fsPath).toLowerCase() !== '.hc') {
			vscode.window.showInformationMessage('Hyperprompt: Open a .hc file to navigate.');
			return null;
		}
		return editor;
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

	const navigateToSource = async (outputLine: number) => {
		if (!previewSourceMap) {
			void vscode.window.showInformationMessage('No source map available for this preview.');
			return;
		}
		const sourceLocation = previewSourceMap.mappings[String(outputLine)];
		if (!sourceLocation) {
			void vscode.window.showInformationMessage(`No source location available for line ${outputLine}.`);
			return;
		}
		try {
			const doc = await vscode.workspace.openTextDocument(sourceLocation.filePath);
			const editor = await vscode.window.showTextDocument(doc);
			// sourceLocation.line is 1-indexed (Core.SourceLocation), VS Code Position is 0-indexed
			const position = new vscode.Position(sourceLocation.line - 1, 0);
			editor.selection = new vscode.Selection(position, position);
			editor.revealRange(new vscode.Range(position, position), vscode.TextEditorRevealType.InCenter);
		} catch (error) {
			void vscode.window.showErrorMessage(`Cannot open file: ${sourceLocation.filePath}`);
		}
	};

	const ensurePreviewPanel = () => {
		if (previewPanel) {
			return previewPanel;
		}
		const panel = vscode.window.createWebviewPanel(
			'hyperpromptPreview',
			'Hyperprompt Preview',
			vscode.ViewColumn.Beside,
			{ enableScripts: true, retainContextWhenHidden: true }
		);
		panel.onDidDispose(() => {
			if (previewPanel === panel) {
				previewPanel = null;
				previewEntryFile = null;
				previewSourceMap = null;
			}
		});
		panel.webview.onDidReceiveMessage((message: {type: string; line?: number}) => {
			if (message.type === 'navigateToSource' && typeof message.line === 'number') {
				void navigateToSource(message.line);
			}
		});
		previewPanel = panel;
		return panel;
	};

	const updatePreviewOutput = async (entryFile: string) => {
		if (!previewPanel) {
			return;
		}
		const client = await ensureEngineReady();
		if (!client) {
			return;
		}
		const params = buildCompileParams(
			entryFile,
			resolveWorkspaceRootForPath(entryFile),
			settings.resolutionMode,
			true
		);
		const compileResult = await runCompileRequest(
			client.request.bind(client),
			params,
			compileTimeoutMs
		);
		previewPanel.webview.html = buildPreviewHtml(compileResult.output ?? '');
		previewSourceMap = compileResult.sourceMap ?? null;
		const activeEditor = vscode.window.activeTextEditor;
		if (activeEditor && activeEditor.document.uri.fsPath === entryFile) {
			sendPreviewScroll(activeEditor);
		}
	};

	const previewCommand = vscode.commands.registerCommand('hyperprompt.showPreview', async () => {
		try {
			const entryFile = getActiveEntryFile('preview');
			if (!entryFile) {
				return;
			}
			const panel = ensurePreviewPanel();
			previewEntryFile = entryFile;
			await updatePreviewOutput(entryFile);
			panel.reveal();
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: preview failed (${String(error)})`);
		}
	});

	const openBesideCommand = vscode.commands.registerCommand('hyperprompt.openBeside', async () => {
		try {
			const editor = getActiveHypercodeEditor();
			if (!editor) {
				return;
			}
			const document = editor.document;

			const client = await ensureEngineReady();
			if (!client) {
				return;
			}

			// Call editor.linkAt to find link at cursor
			const position = editor.selection.active;
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
				vscode.window.showInformationMessage('Hyperprompt: No link at cursor position.');
				return;
			}

			// Call editor.resolve to resolve link target
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
				vscode.window.showErrorMessage(`Hyperprompt: ${describeResolvedTarget(target)}`);
				return;
			}

			// Open file in adjacent editor group (beside)
			await vscode.window.showTextDocument(
				vscode.Uri.file(targetPath),
				{
					viewColumn: vscode.ViewColumn.Beside,
					preview: false
				}
			);
		} catch (error) {
			vscode.window.showErrorMessage(`Hyperprompt: Open Beside failed (${String(error)})`);
		}
	});

	const computeScrollRatio = (editor: vscode.TextEditor): number => {
		const visible = editor.visibleRanges[0];
		const topLine = visible ? visible.start.line : 0;
		const totalLines = Math.max(editor.document.lineCount - 1, 1);
		return Math.min(1, Math.max(0, topLine / totalLines));
	};

	const sendPreviewScroll = (editor: vscode.TextEditor) => {
		if (!previewPanel || !previewEntryFile) {
			return;
		}
		if (editor.document.uri.fsPath !== previewEntryFile) {
			return;
		}
		const ratio = computeScrollRatio(editor);
		previewPanel.webview.postMessage({ type: 'scroll', ratio });
	};

	const resolveWorkspaceRoot = (document: vscode.TextDocument): string => {
		const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
		return workspaceFolder?.uri.fsPath ?? path.dirname(document.uri.fsPath);
	};

	const resolveWorkspaceRootForPath = (filePath: string): string => {
		const uri = vscode.Uri.file(filePath);
		const workspaceFolder = vscode.workspace.getWorkspaceFolder(uri);
		return workspaceFolder?.uri.fsPath ?? path.dirname(filePath);
	};

	const mapSeverity = (severity: string): vscode.DiagnosticSeverity => {
		switch (normalizeSeverity(severity)) {
			case 'warning':
				return vscode.DiagnosticSeverity.Warning;
			case 'info':
				return vscode.DiagnosticSeverity.Information;
			case 'hint':
				return vscode.DiagnosticSeverity.Hint;
			default:
				return vscode.DiagnosticSeverity.Error;
		}
	};

	const toDocumentPosition = (
		document: vscode.TextDocument,
		position: { line: number; character: number }
	): vscode.Position => {
		const safeLine = Math.min(Math.max(position.line, 0), Math.max(document.lineCount - 1, 0));
		const lineText = document.lineAt(safeLine).text;
		const safeCharacter = Math.min(Math.max(position.character, 0), lineText.length);
		return new vscode.Position(safeLine, safeCharacter);
	};

	const toDiagnosticRange = (
		document: vscode.TextDocument,
		range?: { start: { line: number; column: number }; end: { line: number; column: number } }
	): vscode.Range => {
		const zeroBased = toZeroBasedRange(range);
		if (!zeroBased) {
			const start = toDocumentPosition(document, { line: 0, character: 0 });
			return new vscode.Range(start, start);
		}
		const start = toDocumentPosition(document, zeroBased.start);
		const end = toDocumentPosition(document, zeroBased.end);
		return new vscode.Range(start, end);
	};

	const updateDiagnosticsForDocument = async (document: vscode.TextDocument) => {
		if (path.extname(document.uri.fsPath).toLowerCase() !== '.hc') {
			return;
		}
		if (!settings.diagnosticsEnabled) {
			diagnosticCollection.delete(document.uri);
			return;
		}
		const client = await ensureEngineReady();
		if (!client) {
			return;
		}
		const params = buildCompileParams(
			document.uri.fsPath,
			resolveWorkspaceRoot(document),
			settings.resolutionMode,
			false
		);
		const compileResult = await runCompileRequest(
			client.request.bind(client),
			params,
			compileTimeoutMs
		);
		const diagnostics = (compileResult.diagnostics ?? []) as RpcDiagnostic[];
		const vscodeDiagnostics = diagnostics.map((diagnostic) => {
			const range = toDiagnosticRange(document, diagnostic.range);
			const entry = new vscode.Diagnostic(range, diagnostic.message, mapSeverity(diagnostic.severity));
			entry.code = diagnostic.code;
			entry.source = 'Hyperprompt';
			return entry;
		});
		diagnosticCollection.set(document.uri, vscodeDiagnostics);
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
		const diagnosticsDisabled = settings.diagnosticsEnabled && !nextSettings.diagnosticsEnabled;
		settings = nextSettings;
		if (engineChanged) {
			void refreshEngineState(true);
		}
		if (diagnosticsDisabled) {
			diagnosticCollection.clear();
		}
	});

	const diagnosticsWatcher = vscode.workspace.onDidSaveTextDocument((document) => {
		void updateDiagnosticsForDocument(document).catch((error) => {
			console.error(`[hyperprompt] diagnostics failed: ${String(error)}`);
		});
	});

	const previewWatcher = vscode.workspace.onDidSaveTextDocument((document) => {
		if (!previewPanel || !settings.previewAutoUpdate || !previewEntryFile) {
			return;
		}
		const ext = path.extname(document.uri.fsPath).toLowerCase();
		if (ext !== '.hc' && ext !== '.md') {
			return;
		}
		void updatePreviewOutput(previewEntryFile).catch((error) => {
			console.error(`[hyperprompt] preview update failed: ${String(error)}`);
		});
	});

	const previewScrollWatcher = vscode.window.onDidChangeTextEditorVisibleRanges((event) => {
		if (!previewPanel || !previewEntryFile) {
			return;
		}
		sendPreviewScroll(event.textEditor);
	});

	context.subscriptions.push(
		compileCommand,
		compileLenientCommand,
		previewCommand,
		openBesideCommand,
		definitionProvider,
		hoverProvider,
		configWatcher,
		diagnosticsWatcher,
		previewWatcher,
		previewScrollWatcher,
		diagnosticCollection,
		outputChannel,
		{ dispose: () => stopRpcClient() }
	);
}

// This method is called when your extension is deactivated
export function deactivate() {}
