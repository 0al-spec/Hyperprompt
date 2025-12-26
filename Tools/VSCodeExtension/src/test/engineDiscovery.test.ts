import * as assert from 'assert';
import { resolveEngine } from '../engineDiscovery';

const makeError = (code: string): Error & { code: string } => {
	const error = new Error('test');
	return Object.assign(error, { code });
};

suite('Engine Discovery', () => {
	test('returns unsupported-platform on Windows', async () => {
		const result = await resolveEngine({
			platform: 'win32',
			enginePath: '',
			extensionPath: '/ext',
			env: {},
			access: async () => undefined,
			execFile: async () => ({ stdout: '', stderr: '' })
		});

		assert.strictEqual(result.ok, false);
		if (!result.ok) {
			assert.strictEqual(result.reason, 'unsupported-platform');
		}
	});

	test('reports missing binary on PATH', async () => {
		const result = await resolveEngine({
			platform: 'darwin',
			enginePath: '',
			extensionPath: '/ext',
			env: {},
			access: async () => {
				throw makeError('ENOENT');
			},
			execFile: async () => {
				throw makeError('ENOENT');
			}
		});

		assert.strictEqual(result.ok, false);
		if (!result.ok) {
			assert.strictEqual(result.reason, 'not-found');
			assert.ok(result.message.includes('PATH'));
		}
	});

	test('reports non-executable enginePath', async () => {
		const result = await resolveEngine({
			platform: 'darwin',
			enginePath: '/bad/hyperprompt',
			extensionPath: '/ext',
			env: {},
			access: async () => {
				throw makeError('EACCES');
			},
			execFile: async () => ({ stdout: 'editor-rpc', stderr: '' })
		});

		assert.strictEqual(result.ok, false);
		if (!result.ok) {
			assert.strictEqual(result.reason, 'not-executable');
			assert.ok(result.message.includes('/bad/hyperprompt'));
		}
	});
});
