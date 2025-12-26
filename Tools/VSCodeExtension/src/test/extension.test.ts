import * as assert from 'assert';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as vscode from 'vscode';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const fixtureRoot = path.resolve(__dirname, '..', '..', 'src', 'test', 'fixtures', 'workspace');
const fixtureRootTwo = path.resolve(__dirname, '..', '..', 'src', 'test', 'fixtures', 'workspace-two');
const mockEnginePath = path.resolve(__dirname, '..', '..', 'src', 'test', 'fixtures', 'mock-engine.js');
const logFile = path.join(os.tmpdir(), `hyperprompt-vscode-test-${Date.now()}.log`);

const readLogEntries = (): Array<{ method: string; params: Record<string, unknown> }> => {
	if (!fs.existsSync(logFile)) {
		return [];
	}
	return fs
		.readFileSync(logFile, 'utf8')
		.split('\n')
		.filter((line) => line.trim().length > 0)
		.map((line) => JSON.parse(line) as { method: string; params: Record<string, unknown> });
};

const setEnginePath = async (enginePath: string) => {
	const config = vscode.workspace.getConfiguration('hyperprompt');
	await config.update('enginePath', enginePath, vscode.ConfigurationTarget.Workspace);
};

suite('Extension Integration', () => {
	suiteSetup(async () => {
		process.env.HYPERPROMPT_TEST_LOG = logFile;
		if (vscode.workspace.workspaceFolders?.length) {
			return;
		}
		vscode.workspace.updateWorkspaceFolders(0, null, { uri: vscode.Uri.file(fixtureRoot) });
		vscode.workspace.updateWorkspaceFolders(1, null, { uri: vscode.Uri.file(fixtureRootTwo) });
		await setEnginePath(mockEnginePath);
		const config = vscode.workspace.getConfiguration('hyperprompt');
		await config.update('previewAutoUpdate', true, vscode.ConfigurationTarget.Workspace);
		await config.update('diagnosticsEnabled', true, vscode.ConfigurationTarget.Workspace);
		const extension = vscode.extensions.getExtension('0al.hyperprompt');
		if (extension) {
			await extension.activate();
		}
	});

	test('Definition provider resolves link in primary workspace', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRoot, 'main.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		await vscode.window.showTextDocument(doc);

		const results = await vscode.commands.executeCommand<vscode.Location[]>(
			'vscode.executeDefinitionProvider',
			uri,
			new vscode.Position(0, 4)
		);

		assert.ok(results && results.length > 0);
		assert.ok(results[0].uri.fsPath.endsWith(path.join('docs', 'readme.md')));

		const log = readLogEntries().filter((entry) => entry.method === 'editor.resolve');
		assert.ok(log.length > 0);
		const last = log[log.length - 1];
		assert.strictEqual(last.params.workspaceRoot, fixtureRoot);
	});

	test('Definition provider uses multi-root workspace folder', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRootTwo, 'main.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		await vscode.window.showTextDocument(doc);

		await vscode.commands.executeCommand<vscode.Location[]>(
			'vscode.executeDefinitionProvider',
			uri,
			new vscode.Position(0, 4)
		);

		const log = readLogEntries().filter((entry) => entry.method === 'editor.resolve');
		assert.ok(log.length > 0);
		const last = log[log.length - 1];
		assert.strictEqual(last.params.workspaceRoot, fixtureRootTwo);
	});

	test('Compile command runs for active file', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRoot, 'main.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		await vscode.window.showTextDocument(doc);

		await vscode.commands.executeCommand('hyperprompt.compile');
	});

	test('Hover provider returns link metadata', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRoot, 'main.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		await vscode.window.showTextDocument(doc);

		const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
			'vscode.executeHoverProvider',
			uri,
			new vscode.Position(0, 4)
		);

		assert.ok(hovers && hovers.length > 0);
		const contents = hovers[0].contents.map((item) => item.value ?? String(item)).join('\n');
		assert.ok(contents.includes('Markdown file'));
	});

	test('Diagnostics update after save', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRoot, 'broken.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		const editor = await vscode.window.showTextDocument(doc);

		await editor.edit((edit) => {
			edit.insert(new vscode.Position(0, 0), '// ');
		});
		await doc.save();
		await sleep(300);

		const diagnostics = vscode.languages.getDiagnostics(uri);
		assert.ok(diagnostics.length > 0);
	});

	test('Preview command opens webview', async () => {
		const uri = vscode.Uri.file(path.join(fixtureRoot, 'main.hc'));
		const doc = await vscode.workspace.openTextDocument(uri);
		await vscode.window.showTextDocument(doc);

		await vscode.commands.executeCommand('hyperprompt.showPreview');
		await sleep(200);

		const hasWebview = vscode.window.tabGroups.all.some((group) =>
			group.tabs.some((tab) => tab.input instanceof vscode.TabInputWebview)
		);
		assert.ok(hasWebview);
	});

	test('Compile command handles missing engine', async () => {
		await setEnginePath('/missing/hyperprompt');
		await vscode.commands.executeCommand('hyperprompt.compile');
		await setEnginePath(mockEnginePath);
	});

});
