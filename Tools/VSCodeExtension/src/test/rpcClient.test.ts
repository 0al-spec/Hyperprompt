import * as assert from 'assert';
import { EventEmitter } from 'events';
import { PassThrough } from 'stream';
import { RpcClient } from '../rpcClient';

class MockProcess extends EventEmitter {
	public stdin = new PassThrough();
	public stdout = new PassThrough();
	public stderr = new PassThrough();
	public killed = false;

	kill(): void {
		this.killed = true;
		this.emit('exit', 0, null);
	}
}

suite('RPC Client', () => {
	test('resolves response by id', async () => {
		const mock = new MockProcess();
		const client = new RpcClient({
			command: 'hyperprompt',
			args: ['editor-rpc'],
			spawnFn: () => mock as unknown as import('child_process').ChildProcessWithoutNullStreams
		});

		client.start();

		const responsePromise = client.request('editor.indexProject', { workspaceRoot: '/tmp' });

		const payload = JSON.stringify({ jsonrpc: '2.0', id: 1, result: { ok: true } }) + '\n';
		mock.stdout.write(payload);

		const result = await responsePromise;
		assert.deepStrictEqual(result, { ok: true });

		client.dispose();
	});

	test('times out when no response arrives', async () => {
		const mock = new MockProcess();
		const client = new RpcClient({
			command: 'hyperprompt',
			args: ['editor-rpc'],
			spawnFn: () => mock as unknown as import('child_process').ChildProcessWithoutNullStreams
		});

		client.start();

		let didThrow = false;
		try {
			await client.request('editor.indexProject', { workspaceRoot: '/tmp' }, 10);
		} catch (error) {
			didThrow = true;
			assert.ok(String(error).includes('timed out'));
		}

		assert.ok(didThrow);
		client.dispose();
	});
});
