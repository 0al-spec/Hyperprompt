import { execFile } from 'child_process';
import { constants } from 'fs';
import { access as fsAccess } from 'fs/promises';
import * as path from 'path';
import { promisify } from 'util';

export type EngineSource = 'setting' | 'bundled' | 'path';

export type EngineErrorReason =
	| 'unsupported-platform'
	| 'invalid-setting'
	| 'not-found'
	| 'not-executable'
	| 'missing-editor-trait'
	| 'probe-failed';

export type EngineResolution =
	| { ok: true; command: string; source: EngineSource }
	| { ok: false; reason: EngineErrorReason; message: string };

export type ResolveEngineOptions = {
	platform: NodeJS.Platform;
	enginePath: string;
	extensionPath: string;
	env: NodeJS.ProcessEnv;
	bundledRelativePath?: string;
	access?: (filePath: string) => Promise<void>;
	execFile?: (command: string, args: string[], options: { env: NodeJS.ProcessEnv; timeout: number; maxBuffer: number }) => Promise<{ stdout: string; stderr: string }>;
};

const execFileAsync = promisify(execFile);
const defaultBundledRelativePath = path.join('bin', 'hyperprompt');

export const isSupportedPlatform = (platform: NodeJS.Platform): boolean => {
	return platform === 'darwin' || platform === 'linux';
};

const getErrorCode = (error: unknown): string | undefined => {
	if (!error || typeof error !== 'object') {
		return undefined;
	}
	if ('code' in error) {
		const code = (error as { code?: string }).code;
		return code ? String(code) : undefined;
	}
	return undefined;
};

const probeEditorRpc = async (
	command: string,
	env: NodeJS.ProcessEnv,
	execFn: (command: string, args: string[], options: { env: NodeJS.ProcessEnv; timeout: number; maxBuffer: number }) => Promise<{ stdout: string; stderr: string }>,
	notFoundMessage: string,
	probeFailedMessage: string
): Promise<EngineResolution> => {
	try {
		const { stdout, stderr } = await execFn(command, ['--help'], {
			env,
			timeout: 2000,
			maxBuffer: 1024 * 1024
		});
		const output = `${stdout}\n${stderr}`;
		if (!output.includes('editor-rpc')) {
			return {
				ok: false,
				reason: 'missing-editor-trait',
				message:
					'Hyperprompt binary does not expose editor-rpc. Rebuild with `swift build --traits Editor` and update PATH or `hyperprompt.enginePath`.'
			};
		}
		return { ok: true, command, source: 'path' };
	} catch (error) {
		const code = getErrorCode(error);
		if (code === 'ENOENT') {
			return {
				ok: false,
				reason: 'not-found',
				message: notFoundMessage
			};
		}
		return {
			ok: false,
			reason: 'probe-failed',
			message: `${probeFailedMessage}: ${String(error)}`
		};
	}
};

const validateExecutable = async (
	filePath: string,
	accessFn: (filePath: string) => Promise<void>,
	notFoundMessage: string,
	notExecutableMessage: string
): Promise<EngineResolution | null> => {
	try {
		await accessFn(filePath);
		return null;
	} catch (error) {
		const code = getErrorCode(error);
		if (code === 'ENOENT') {
			return { ok: false, reason: 'not-found', message: notFoundMessage };
		}
		return { ok: false, reason: 'not-executable', message: notExecutableMessage };
	}
};

export const resolveEngine = async (options: ResolveEngineOptions): Promise<EngineResolution> => {
	if (!isSupportedPlatform(options.platform)) {
		return {
			ok: false,
			reason: 'unsupported-platform',
			message: 'Hyperprompt is not supported on Windows yet. Use macOS or Linux.'
		};
	}

	const accessFn = options.access ?? ((filePath: string) => fsAccess(filePath, constants.X_OK));
	const execFn = options.execFile ?? ((command: string, args: string[], execOptions: { env: NodeJS.ProcessEnv; timeout: number; maxBuffer: number }) => {
		return execFileAsync(command, args, execOptions) as Promise<{ stdout: string; stderr: string }>;
	});

	const enginePath = options.enginePath.trim();
	if (enginePath.length > 0) {
		if (!path.isAbsolute(enginePath)) {
			return {
				ok: false,
				reason: 'invalid-setting',
				message: 'hyperprompt.enginePath must be an absolute path. Clear it to use PATH.'
			};
		}
		const failure = await validateExecutable(
			enginePath,
			accessFn,
			`Hyperprompt engine not found at ${enginePath}. Update hyperprompt.enginePath or PATH.`,
			`Hyperprompt engine is not executable at ${enginePath}. Run chmod +x or rebuild.`
		);
		if (failure) {
			return failure;
		}

		const probe = await probeEditorRpc(
			enginePath,
			options.env,
			execFn,
			`Hyperprompt engine not found at ${enginePath}. Update hyperprompt.enginePath or PATH.`,
			'Failed to validate Hyperprompt engine'
		);
		if (!probe.ok) {
			return probe;
		}
		return { ok: true, command: enginePath, source: 'setting' };
	}

	const bundledRelativePath = options.bundledRelativePath ?? defaultBundledRelativePath;
	const bundledPath = path.join(options.extensionPath, bundledRelativePath);
	const bundledFailure = await validateExecutable(
		bundledPath,
		accessFn,
		'',
		`Bundled Hyperprompt engine is not executable at ${bundledPath}. Reinstall the extension or set hyperprompt.enginePath.`
	);
	if (bundledFailure) {
		if (bundledFailure.reason !== 'not-found' || bundledFailure.message.length > 0) {
			return bundledFailure;
		}
	} else {
		const probe = await probeEditorRpc(
			bundledPath,
			options.env,
			execFn,
			`Bundled Hyperprompt engine not found at ${bundledPath}. Reinstall the extension or set hyperprompt.enginePath.`,
			'Failed to validate bundled Hyperprompt engine'
		);
		if (!probe.ok) {
			return probe;
		}
		return { ok: true, command: bundledPath, source: 'bundled' };
	}

	const probe = await probeEditorRpc(
		'hyperprompt',
		options.env,
		execFn,
		'Hyperprompt engine not found on PATH. Install it or set `hyperprompt.enginePath`.',
		'Failed to validate Hyperprompt engine'
	);
	if (!probe.ok) {
		return probe;
	}
	return { ok: true, command: 'hyperprompt', source: 'path' };
};

export const engineDiscoveryDefaults = {
	bundledRelativePath: defaultBundledRelativePath
};
