import { spawn, ChildProcessWithoutNullStreams } from 'child_process';

export type RpcClientOptions = {
	command: string;
	args: string[];
	env?: NodeJS.ProcessEnv;
	onExit?: (code: number | null, signal: NodeJS.Signals | null) => void;
	spawnFn?: (command: string, args: string[]) => ChildProcessWithoutNullStreams;
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

	start(): boolean {
		if (this.process) {
			return true;
		}

		const spawnFn = this.options.spawnFn ?? ((command: string, args: string[]) => {
			return spawn(command, args, { stdio: 'pipe', env: this.options.env ?? process.env });
		});

		this.process = spawnFn(this.options.command, this.options.args);
		this.process.stdout.on('data', (data) => this.onData(data.toString()));
		this.process.stderr.on('data', (data) => {
			console.error(`[hyperprompt-rpc] ${data.toString().trim()}`);
		});
		this.process.on('error', (error) => {
			console.error(`[hyperprompt-rpc] failed to start: ${error}`);
			this.process = null;
			this.failAllPending(new Error('RPC process failed to start. Ensure hyperprompt is on PATH.'));
		});
		this.process.on('exit', (code, signal) => {
			this.process = null;
			this.failAllPending(new Error('RPC process exited.'));
			this.options.onExit?.(code, signal);
		});

		return true;
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
			this.start();
		}
		if (!this.process || !this.process.stdin.writable) {
			return Promise.reject(new Error('RPC process is not running. Ensure hyperprompt is on PATH.'));
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
