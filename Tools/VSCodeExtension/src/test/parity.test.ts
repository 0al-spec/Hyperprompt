import * as assert from 'assert';
import { execFile } from 'child_process';
import { promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { promisify } from 'util';
import { buildCompileParams, runCompileRequest } from '../compileCommand';
import { RpcClient } from '../rpcClient';

const execFileAsync = promisify(execFile);
const fixtureRoot = path.resolve(__dirname, '..', '..', 'src', 'test', 'fixtures', 'workspace');
const entryFile = path.join(fixtureRoot, 'main.hc');

const resolveHyperpromptPath = async (): Promise<string | null> => {
	const envPath = (process.env.HYPERPROMPT_PATH ?? '').trim();
	const candidates = envPath.length > 0
		? [envPath]
		: [path.resolve(__dirname, '..', '..', '..', '..', '.build', 'debug', 'hyperprompt')];

	for (const candidate of candidates) {
		try {
			await fs.access(candidate);
			const { stdout, stderr } = await execFileAsync(candidate, ['--help']);
			const output = `${stdout}\n${stderr}`;
			if (!output.includes('editor-rpc')) {
				return null;
			}
			return candidate;
		} catch {
			continue;
		}
	}
	return null;
};

suite('CLI vs RPC parity', () => {
	test('matches compiled output for the workspace fixture', async function () {
		const command = await resolveHyperpromptPath();
		if (!command) {
			this.skip();
			return;
		}

		const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hyperprompt-parity-'));
		const outputPath = path.join(tempDir, 'cli.md');
		const manifestPath = path.join(tempDir, 'cli.json');

		await execFileAsync(command, ['compile', entryFile, '--root', fixtureRoot, '--output', outputPath, '--manifest', manifestPath]);
		const cliOutput = await fs.readFile(outputPath, 'utf8');

		const client = new RpcClient({ command, args: ['editor-rpc'] });
		client.start();
		try {
			const params = buildCompileParams(entryFile, fixtureRoot, 'strict', true);
			const result = await runCompileRequest(client.request.bind(client), params, 5000);
			const rpcOutput = result.output ?? '';
			assert.strictEqual(rpcOutput.trimEnd(), cliOutput.trimEnd());
		} finally {
			client.dispose();
		}
	});
});
