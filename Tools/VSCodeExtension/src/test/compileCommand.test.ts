import * as assert from 'assert';
import { buildCompileParams, runCompileRequest, CompileParams } from '../compileCommand';

suite('Compile Command', () => {
	test('buildCompileParams uses workspace root fallback', () => {
		const params = buildCompileParams('/workspace/project/main.hc', undefined, 'strict', true);
		assert.strictEqual(params.workspaceRoot, '/workspace/project');
		assert.strictEqual(params.includeOutput, true);
		assert.strictEqual(params.mode, 'strict');
	});

	test('runCompileRequest forwards params to RPC', async () => {
		let capturedMethod = '';
		let capturedParams: CompileParams | null = null;
		let capturedTimeout = 0;

		const request = async (method: string, params: CompileParams, timeoutMs: number) => {
			capturedMethod = method;
			capturedParams = params;
			capturedTimeout = timeoutMs;
			return { output: '# Title', diagnostics: [], hasErrors: false };
		};

		const params = buildCompileParams('/workspace/project/main.hc', '/workspace', 'lenient', true);
		const result = await runCompileRequest(request, params, 5000);

		assert.strictEqual(capturedMethod, 'editor.compile');
		assert.strictEqual(capturedParams?.entryFile, '/workspace/project/main.hc');
		assert.strictEqual(capturedParams?.workspaceRoot, '/workspace');
		assert.strictEqual(capturedParams?.includeOutput, true);
		assert.strictEqual(capturedParams?.mode, 'lenient');
		assert.strictEqual(capturedTimeout, 5000);
		assert.strictEqual(result.output, '# Title');
	});
});
