import * as path from 'path';

export type ResolutionMode = 'strict' | 'lenient';

export type CompileParams = {
	entryFile: string;
	workspaceRoot: string;
	includeOutput: boolean;
	mode: ResolutionMode;
};

export type SourceLocation = {
	filePath: string;
	line: number;
	column: number;
};

export type SourceMap = {
	mappings: Record<string, SourceLocation>;
};

export type CompileResult = {
	output?: string;
	diagnostics?: unknown[];
	hasErrors?: boolean;
	sourceMap?: SourceMap;
};

export type CompileRequest = (method: string, params: CompileParams, timeoutMs: number) => Promise<unknown>;

export const buildCompileParams = (
	entryFile: string,
	workspaceRoot: string | undefined,
	mode: ResolutionMode,
	includeOutput: boolean
): CompileParams => {
	return {
		entryFile,
		workspaceRoot: workspaceRoot ?? path.dirname(entryFile),
		includeOutput,
		mode
	};
};

export const runCompileRequest = async (
	request: CompileRequest,
	params: CompileParams,
	timeoutMs: number
): Promise<CompileResult> => {
	const result = await request('editor.compile', params, timeoutMs);
	return result as CompileResult;
};
