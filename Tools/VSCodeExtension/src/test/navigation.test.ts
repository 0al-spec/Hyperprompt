import * as assert from 'assert';
import {
	buildLinkAtParams,
	buildResolveParams,
	describeResolvedTarget,
	resolvedTargetPath,
	runLinkAtRequest,
	runResolveRequest
} from '../navigation';

suite('Navigation', () => {
	test('buildLinkAtParams converts to 1-based positions', () => {
		const params = buildLinkAtParams('/workspace/main.hc', 0, 4);
		assert.strictEqual(params.filePath, '/workspace/main.hc');
		assert.strictEqual(params.line, 1);
		assert.strictEqual(params.column, 5);
	});

	test('buildResolveParams uses workspace root fallback', () => {
		const params = buildResolveParams('docs/readme.md', '/workspace/main.hc');
		assert.strictEqual(params.linkPath, 'docs/readme.md');
		assert.strictEqual(params.sourceFile, '/workspace/main.hc');
		assert.strictEqual(params.workspaceRoot, '/workspace');
	});

	test('runLinkAtRequest forwards params to RPC', async () => {
		let capturedMethod = '';
		let capturedParams: unknown = null;
		let capturedTimeout = 0;

		const request = async (method: string, params: unknown, timeoutMs: number) => {
			capturedMethod = method;
			capturedParams = params;
			capturedTimeout = timeoutMs;
			return { literal: 'docs/readme.md' };
		};

		const result = await runLinkAtRequest(request, { filePath: '/a.hc', line: 1, column: 2 }, 5000);
		assert.strictEqual(capturedMethod, 'editor.linkAt');
		assert.deepStrictEqual(capturedParams, { filePath: '/a.hc', line: 1, column: 2 });
		assert.strictEqual(capturedTimeout, 5000);
		assert.strictEqual(result?.literal, 'docs/readme.md');
	});

	test('runResolveRequest forwards params to RPC', async () => {
		let capturedMethod = '';
		let capturedParams: unknown = null;

		const request = async (method: string, params: unknown, _timeoutMs: number) => {
			capturedMethod = method;
			capturedParams = params;
			return { type: 'markdownFile', path: '/workspace/docs/readme.md' };
		};

		const result = await runResolveRequest(
			request,
			{ linkPath: 'docs/readme.md', sourceFile: '/workspace/main.hc', workspaceRoot: '/workspace' },
			4000
		);
		assert.strictEqual(capturedMethod, 'editor.resolve');
		assert.deepStrictEqual(capturedParams, {
			linkPath: 'docs/readme.md',
			sourceFile: '/workspace/main.hc',
			workspaceRoot: '/workspace'
		});
		assert.strictEqual(result.type, 'markdownFile');
	});

	test('resolvedTargetPath returns file paths for file targets', () => {
		assert.strictEqual(
			resolvedTargetPath({ type: 'markdownFile', path: '/docs/readme.md' }),
			'/docs/readme.md'
		);
		assert.strictEqual(
			resolvedTargetPath({ type: 'hypercodeFile', path: '/docs/main.hc' }),
			'/docs/main.hc'
		);
		assert.strictEqual(resolvedTargetPath({ type: 'inlineText' }), null);
	});

	test('describeResolvedTarget formats output', () => {
		assert.strictEqual(
			describeResolvedTarget({ type: 'hypercodeFile', path: '/docs/main.hc' }),
			'Hypercode file: /docs/main.hc'
		);
		assert.strictEqual(
			describeResolvedTarget({ type: 'forbidden', fileExtension: 'exe' }),
			'Forbidden extension: .exe'
		);
	});
});
