import { spawn, ChildProcessWithoutNullStreams } from 'child_process';

export type RpcClientOptions = {
	command: string;
	args: string[];
	onExit?: (code: number | null, signal: NodeJS.Signals | null) => void;
};

export type JsonRpcRequest = {
	jsonrpc: '2.0';
	id: number;
	method: string;
	params?: unknown;
};

export type JsonRpcResponse = {
	jsonrpc: '2.0';
	id?: number;
	result?: unknown;
	error?: { code: number; message: string; data?: unknown };
};

export class RpcClient {
	private process: ChildProcessWithoutNullStreams | null = null;
	private buffer = '';
	private nextId = 1;
	private pending = new Map<number, { resolve: (value: unknown) => void; reject: (error: Error) => void; timer: NodeJS.Timeout }>;
	private readonly options: RpcClientOptions;

	constructor(options: RpcClientOptions) {
		this.options = options;
	}

	start(): void {
		if (this.process) {
			return;
		}

		this.process = spawn(this.options.command, this.options.args, { stdio: 'pipe' });
		this.process.stdout.on('data', (data) => this.onData(data.toString()));
		this.process.stderr.on('data', (data) => {
			console.error(`[hyperprompt-rpc] ${data.toString().trim()}`);
		});
		this.process.on('exit', (code, signal) => {
			this.process = null;
			this.failAllPending(new Error('RPC process exited.'));
			this.options.onExit?.(code, signal);
		});
	}

	stop(): void {
		if (!this.process) {
			return;
		}

		this.process.kill();
		this.process = null;
		this.failAllPending(new Error('RPC process stopped.'));
	}

	dispose(): void {
		this.stop();
	}

	request(method: string, params?: unknown, timeoutMs = 5000): Promise<unknown> {
		if (!this.process || !this.process.stdin.writable) {
			return Promise.reject(new Error('RPC process is not running.'));
		}

		const id = this.nextId++;
		const request: JsonRpcRequest = { jsonrpc: '2.0', id, method, params };
		const payload = JSON.stringify(request) + '\n';

		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => {
				this.pending.delete(id);
				reject(new Error(`RPC request timed out: ${method}`));
			}, timeoutMs);

			this.pending.set(id, { resolve, reject, timer });
			this.process?.stdin.write(payload);
		});
	}

	private onData(chunk: string): void {
		this.buffer += chunk;
		let newlineIndex = this.buffer.indexOf('\n');
		while (newlineIndex >= 0) {
			const line = this.buffer.slice(0, newlineIndex).trim();
			this.buffer = this.buffer.slice(newlineIndex + 1);
			if (line.length > 0) {
				this.handleLine(line);
			}
			newlineIndex = this.buffer.indexOf('\n');
		}
	}

	private handleLine(line: string): void {
		let response: JsonRpcResponse;
		try {
			response = JSON.parse(line) as JsonRpcResponse;
		} catch (error) {
			console.error('[hyperprompt-rpc] Invalid JSON response:', line);
			return;
		}

		if (response.id === undefined) {
			return;
		}

		const pending = this.pending.get(response.id);
		if (!pending) {
			return;
		}

		clearTimeout(pending.timer);
		this.pending.delete(response.id);

		if (response.error) {
			pending.reject(new Error(response.error.message));
			return;
		}

		pending.resolve(response.result);
	}

	private failAllPending(error: Error): void {
		for (const entry of this.pending.values()) {
			clearTimeout(entry.timer);
			entry.reject(error);
		}
		this.pending.clear();
	}
}
